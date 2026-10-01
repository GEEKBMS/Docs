#!/usr/bin/env bash
# Atomically publish a VitePress tarball to /var/www/geekbms-docs and reload nginx.
# Run as root: remote-publish.sh <publish_dir> <git_sha>
# Does not issue or delete Let's Encrypt certificates.
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
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
REL="$ROOT/releases/${STAMP}-${SHA}"

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

if [[ -f "$CERT" && -f "$KEY" ]]; then
  cp "$PUBLISH_DIR/nginx/docs.geekbms.com.https.conf" "$NGINX_CONF"
  MODE="https"
else
  cp "$PUBLISH_DIR/nginx/docs.geekbms.com.http.conf" "$NGINX_CONF"
  MODE="http"
fi
NGINX_INSTALLED=1

nginx -t
if command -v systemctl >/dev/null 2>&1 && systemctl cat nginx.service >/dev/null 2>&1; then
  systemctl reload nginx
else
  nginx -s reload
fi

trap - ERR
if [[ -n "$PREV_NGINX" ]]; then
  rm -f "$PREV_NGINX"
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
