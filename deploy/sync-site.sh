#!/usr/bin/env bash
# Run from your laptop. Syncs this repo's public web files to the VM and reloads Nginx.
#
# Usage:
#   export DEPLOY_REMOTE=ubuntu@YOUR_PUBLIC_IP
#   bash deploy/sync-site.sh
#
# Optional:
#   SITE_ROOT=/var/www/haranshvir  (must match setup-server.sh on the server)

set -euo pipefail

REMOTE="${DEPLOY_REMOTE:?Set DEPLOY_REMOTE, e.g. ubuntu@203.0.113.10}"
SITE_ROOT="${SITE_ROOT:-/var/www/haranshvir}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="site-upload-$$"

rsync -avz --delete \
  --exclude '.git' \
  --exclude '.cursor' \
  --exclude 'deploy' \
  --exclude 'HOSTING.md' \
  --exclude '.DS_Store' \
  "$ROOT/" "$REMOTE:/tmp/$TMP/"

ssh "$REMOTE" "sudo rsync -a --delete /tmp/$TMP/ $SITE_ROOT/ && sudo chown -R www-data:www-data $SITE_ROOT && rm -rf /tmp/$TMP && sudo nginx -t && sudo systemctl reload nginx"

echo "Deployed to $REMOTE:$SITE_ROOT"
