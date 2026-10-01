#!/usr/bin/env bash
# Publish the packed site and reload the docs vhost.
# Usage: remote-publish.sh <publish_dir> <git_sha>
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "remote-publish.sh must run as root" >&2
  exit 1
fi

PUBLISH_DIR="${1:?publish dir required}"
SHA="$(printf '%s' "${2:-manual}" | tr -cd 'a-zA-Z0-9' | cut -c1-12)"
if [[ -z "$SHA" ]]; then
  SHA="manual"
fi

ROOT=/var/www/geekbms-docs
NGINX_CONF=/etc/nginx/conf.d/docs.geekbms.com.conf
CERT=/etc/letsencrypt/live/docs.geekbms.com/fullchain.pem
KEY=/etc/letsencrypt/live/docs.geekbms.com/privkey.pem
CERTBOT_EMAIL=amzhy8@163.com
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
REL="$ROOT/releases/${STAMP}-${SHA}"

reload_nginx() {
  if command -v systemctl >/dev/null 2>&1 && systemctl cat nginx.service >/dev/null 2>&1; then
    systemctl reload nginx
  else
    nginx -s reload
  fi
}

cert_present() {
  [[ -f "$CERT" && -f "$KEY" ]]
}

install_certbot() {
  if command -v certbot >/dev/null 2>&1; then
    return 0
  fi
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "certbot is missing and apt-get is not available" >&2
    return 1
  fi
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  # certbot only. Skip recommended nginx plugins so apt does not touch www.
  apt-get install -y --no-install-recommends \
    -o Dpkg::Options::=--force-confdef \
    -o Dpkg::Options::=--force-confold \
    certbot
}

# Issue the docs name only. --webroot does not rewrite nginx, so www stays as it is.
issue_docs_cert() {
  if cert_present; then
    echo "certificate already present; skipping certbot"
    return 0
  fi
  install_certbot || return 1
  local status=0
  certbot certonly \
    --non-interactive \
    --agree-tos \
    --email "$CERTBOT_EMAIL" \
    --webroot \
    -w "$ROOT/current" \
    -d docs.geekbms.com \
    --keep-until-expiring \
    --deploy-hook "nginx -t && (systemctl reload nginx || nginx -s reload)" \
    || status=$?
  if ! cert_present; then
    echo "certbot did not create $CERT (exit $status)" >&2
    return 1
  fi
  if [[ "$status" -ne 0 ]]; then
    echo "certbot exit $status but certificate files exist; continuing" >&2
  fi
}

# Swap in the docs HTTPS server. On nginx -t failure, put the HTTP file back.
enable_https() {
  local backup
  backup="$(mktemp)"
  cp "$NGINX_CONF" "$backup"
  cp "$PUBLISH_DIR/nginx/docs.geekbms.com.https.conf" "$NGINX_CONF"
  if nginx -t; then
    reload_nginx
    rm -f "$backup"
    echo "enabled HTTPS for docs.geekbms.com"
    return 0
  fi
  echo "nginx -t failed for the HTTPS config; restoring the HTTP site" >&2
  cp "$backup" "$NGINX_CONF"
  rm -f "$backup"
  if nginx -t; then
    reload_nginx
  else
    echo "restored HTTP config failed nginx -t; left the running nginx process unchanged" >&2
  fi
  return 1
}

test -f "$PUBLISH_DIR/site.tar.gz"
test -f "$PUBLISH_DIR/nginx/docs.geekbms.com.http.conf"
test -f "$PUBLISH_DIR/nginx/docs.geekbms.com.https.conf"

if tar -tzf "$PUBLISH_DIR/site.tar.gz" | grep -E '(^/|(^|/)\.\.(/|$))' >/dev/null; then
  echo "refusing site tarball with absolute or parent paths" >&2
  exit 1
fi

if [[ -e "$ROOT/current" && ! -L "$ROOT/current" ]]; then
  echo "refusing to replace non-symlink $ROOT/current" >&2
  exit 1
fi

mkdir -p "$ROOT/releases" "$REL"
tar -xzf "$PUBLISH_DIR/site.tar.gz" -C "$REL"
test -f "$REL/index.html"
chmod -R a+rX "$REL"

PREV=""
if [[ -L "$ROOT/current" ]]; then
  PREV="$(readlink -f "$ROOT/current" || true)"
fi

PREV_NGINX=""
if [[ -f "$NGINX_CONF" ]]; then
  PREV_NGINX="$(mktemp)"
  cp "$NGINX_CONF" "$PREV_NGINX"
fi

SWAPPED=0
NGINX_INSTALLED=0

rollback() {
  trap - ERR
  if [[ "$SWAPPED" -eq 0 && "$NGINX_INSTALLED" -eq 0 ]]; then
    rm -rf "$REL"
    return
  fi
  if [[ "$SWAPPED" -eq 1 ]]; then
    if [[ -n "$PREV" && -d "$PREV" ]]; then
      ln -sfn "$PREV" "$ROOT/current"
    else
      rm -f "$ROOT/current"
    fi
  fi
  if [[ "$NGINX_INSTALLED" -eq 1 ]]; then
    if [[ -n "$PREV_NGINX" ]]; then
      cp "$PREV_NGINX" "$NGINX_CONF"
    else
      rm -f "$NGINX_CONF"
    fi
  fi
  if [[ "$(readlink -f "$ROOT/current" 2>/dev/null || true)" != "$REL" ]]; then
    rm -rf "$REL"
  fi
  echo "publish failed; rolled back docs.geekbms.com" >&2
}
trap rollback ERR

ln -sfn "$REL" "$ROOT/current"
SWAPPED=1

if cert_present; then
  cp "$PUBLISH_DIR/nginx/docs.geekbms.com.https.conf" "$NGINX_CONF"
  MODE="https"
else
  cp "$PUBLISH_DIR/nginx/docs.geekbms.com.http.conf" "$NGINX_CONF"
  MODE="http"
fi
NGINX_INSTALLED=1

nginx -t
reload_nginx

trap - ERR
if [[ -n "$PREV_NGINX" ]]; then
  rm -f "$PREV_NGINX"
fi

# The site publish is committed. Certificate issuance must not roll it back.
if [[ "$MODE" == "http" ]]; then
  if ! issue_docs_cert; then
    echo "certificate was not issued; docs.geekbms.com stays on HTTP" >&2
    exit 1
  fi
  if ! enable_https; then
    echo "HTTPS nginx config was not enabled; docs.geekbms.com stays on HTTP" >&2
    exit 1
  fi
  MODE="https"
fi

current_real="$(readlink -f "$ROOT/current")"
mapfile -t releases < <(ls -1dt "$ROOT"/releases/*)
kept_old=0
for dir in "${releases[@]}"; do
  real="$(readlink -f "$dir")"
  if [[ "$real" == "$current_real" ]]; then
    continue
  fi
  kept_old=$((kept_old + 1))
  if [[ "$kept_old" -gt 4 ]]; then
    rm -rf "$dir"
  fi
done

echo "published $REL ($MODE) -> $ROOT/current"
