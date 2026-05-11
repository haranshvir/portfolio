#!/usr/bin/env bash
# Run on the OCI instance as a user with sudo (e.g. ubuntu).
# Usage: copy the project to the VM (or clone), then:
#   bash deploy/setup-server.sh
#
# After this script: point DNS at this VM, deploy files, then run Certbot (DNS must resolve for TLS).

set -euo pipefail

DOMAIN_APEX="${DOMAIN_APEX:-haranshvir.com}"
DOMAIN_WWW="${DOMAIN_WWW:-www.haranshvir.com}"
SITE_ROOT="${SITE_ROOT:-/var/www/haranshvir}"
NGINX_SITE="${NGINX_SITE:-personal}"

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Run as a normal user with sudo, not as root." >&2
  exit 1
fi

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nginx certbot python3-certbot-nginx

sudo mkdir -p "$SITE_ROOT"
sudo chown -R www-data:www-data "$SITE_ROOT"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_SRC="$SCRIPT_DIR/nginx-site.conf"
CONF_DST="/etc/nginx/sites-available/$NGINX_SITE.conf"

if [[ ! -f "$CONF_SRC" ]]; then
  echo "Missing $CONF_SRC" >&2
  exit 1
fi

sudo cp "$CONF_SRC" "$CONF_DST"
sudo sed -i "s/server_name .*/server_name $DOMAIN_APEX $DOMAIN_WWW;/" "$CONF_DST"

sudo ln -sf "$CONF_DST" "/etc/nginx/sites-enabled/$NGINX_SITE.conf"
if [[ -f /etc/nginx/sites-enabled/default ]]; then
  sudo rm -f /etc/nginx/sites-enabled/default
fi

sudo nginx -t
sudo systemctl enable --now nginx
sudo systemctl reload nginx

echo ""
echo "Nginx is serving HTTP on port 80. Site root: $SITE_ROOT"
echo "Deploy from your laptop with deploy/sync-site.sh (sets DEPLOY_REMOTE)."
echo ""
echo "When DNS points to this instance, obtain TLS certificates:"
echo "  sudo certbot --nginx -d $DOMAIN_WWW -d $DOMAIN_APEX"
echo ""
echo "During certbot, pick whether visitors should use www or apex (HTTP→HTTPS redirect is added automatically)."
echo "Verify renewal: sudo certbot renew --dry-run"
