#!/usr/bin/env bash
# Pack is uploaded by GitHub Actions. This script copies it to the Aliyun host
# and runs deploy/remote-publish.sh. Requires ALIYUN_HOST, ALIYUN_USER, ALIYUN_SSH_KEY.
set -euo pipefail

: "${ALIYUN_HOST:?Set the ALIYUN_HOST secret}"
: "${ALIYUN_USER:?Set the ALIYUN_USER secret}"
: "${ALIYUN_SSH_KEY:?Set the ALIYUN_SSH_KEY secret}"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ARTIFACT="${ROOT_DIR}/.deploy-artifact/site.tar.gz"
if [[ ! -f "$ARTIFACT" ]]; then
  echo "missing $ARTIFACT" >&2
  exit 1
fi

SHA="${GITHUB_SHA:-manual}"
if [[ ! "$SHA" =~ ^[0-9a-fA-F]{7,64}$ ]]; then
  SHA="manual"
fi

RUN_ID="$(printf '%s' "${GITHUB_RUN_ID:-local}" | tr -cd 'a-zA-Z0-9')"
if [[ -z "$RUN_ID" ]]; then
  RUN_ID="local"
fi
REMOTE_DIR="/tmp/geekbms-docs-publish-${RUN_ID}"

install -m 700 -d "${HOME}/.ssh"
KEY_FILE="${HOME}/.ssh/geekbms_docs_aliyun"
printf '%s\n' "$ALIYUN_SSH_KEY" | tr -d '\r' > "$KEY_FILE"
chmod 600 "$KEY_FILE"

if ! ssh-keyscan -H "$ALIYUN_HOST" >> "${HOME}/.ssh/known_hosts"; then
  echo "ssh-keyscan failed for ALIYUN_HOST" >&2
  rm -f "$KEY_FILE"
  exit 1
fi

SSH_OPTS=(
  -i "$KEY_FILE"
  -o IdentitiesOnly=yes
  -o StrictHostKeyChecking=yes
  -o BatchMode=yes
)

cleanup_remote() {
  ssh "${SSH_OPTS[@]}" "${ALIYUN_USER}@${ALIYUN_HOST}" "rm -rf $(printf '%q' "$REMOTE_DIR")" || true
  rm -f "$KEY_FILE"
}
trap cleanup_remote EXIT

ssh "${SSH_OPTS[@]}" "${ALIYUN_USER}@${ALIYUN_HOST}" \
  "mkdir -p $(printf '%q' "$REMOTE_DIR/nginx") && chmod 700 $(printf '%q' "$REMOTE_DIR")"

scp "${SSH_OPTS[@]}" \
  "$ARTIFACT" \
  "${ROOT_DIR}/deploy/remote-publish.sh" \
  "${ALIYUN_USER}@${ALIYUN_HOST}:${REMOTE_DIR}/"

scp "${SSH_OPTS[@]}" \
  "${ROOT_DIR}/deploy/nginx/docs.geekbms.com.http.conf" \
  "${ROOT_DIR}/deploy/nginx/docs.geekbms.com.https.conf" \
  "${ALIYUN_USER}@${ALIYUN_HOST}:${REMOTE_DIR}/nginx/"

ssh "${SSH_OPTS[@]}" "${ALIYUN_USER}@${ALIYUN_HOST}" \
  "if [ \"\$(id -u)\" -eq 0 ]; then bash $(printf '%q' "$REMOTE_DIR/remote-publish.sh") $(printf '%q' "$REMOTE_DIR") $(printf '%q' "$SHA"); else sudo -n bash $(printf '%q' "$REMOTE_DIR/remote-publish.sh") $(printf '%q' "$REMOTE_DIR") $(printf '%q' "$SHA"); fi"
