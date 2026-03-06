#!/bin/bash
set -euo pipefail

log() { echo "[INFO] $*"; }
die() { echo "[ERROR] $*" >&2; exit 1; }

# ------------------------------------------------------------
# Global configuration (single source of truth for the domain)
# ------------------------------------------------------------
DOMAIN="n8n.joseluissr.com"
EMAIL="jose.luis.sastoque.rey@gmail.com"

# ------------------------------------------------------------
# Update OS packages
# ------------------------------------------------------------
log "Updating OS packages..."
sudo dnf update -y

# ------------------------------------------------------------
# Install Docker and start the daemon
# ------------------------------------------------------------
log "Installing Docker..."
sudo dnf install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo docker version >/dev/null

# ------------------------------------------------------------
# Install Docker Compose v2 plugin (architecture-aware)
# ------------------------------------------------------------
log "Installing Docker Compose v2 plugin..."
ARCH="$(uname -m)"
case "${ARCH}" in
x86_64) COMPOSE_BIN="docker-compose-linux-x86_64" ;;
aarch64|arm64) COMPOSE_BIN="docker-compose-linux-aarch64" ;;
*) die "Unsupported architecture: ${ARCH}" ;;
esac

sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -fsSL \
"https://github.com/docker/compose/releases/latest/download/${COMPOSE_BIN}" \
-o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
sudo docker compose version >/dev/null

# ------------------------------------------------------------
# Start n8n stack BEFORE configuring Nginx
# (Avoid temporary 502s while Nginx is up but n8n isn't ready)
# ------------------------------------------------------------
log "Starting n8n stack..."
cd /tmp/whatsapp-calendar-bot-develop/docker
sudo docker compose up -d

# ------------------------------------------------------------
# Install and configure Nginx reverse proxy AFTER n8n is running
# ------------------------------------------------------------
log "Installing Nginx..."
sudo dnf install -y nginx
sudo systemctl enable nginx

log "Creating Nginx reverse proxy configuration..."
sudo cp /tmp/whatsapp-calendar-bot-develop/nginx/reverse-proxy.conf /etc/nginx/conf.d/reverse-proxy.conf

# Validate Nginx configuration and start/restart it
sudo nginx -t
sudo systemctl restart nginx

# ------------------------------------------------------------
# Show running containers to confirm successful deployment
# ------------------------------------------------------------
log "Containers:"
sudo docker ps

# ------------------------------------------------------------
# Install Certbot for Let's Encrypt SSL certificate management
# ------------------------------------------------------------
sudo dnf install -y certbot python3-certbot-nginx

# ------------------------------------------------------------
# Obtain and install SSL certificate for the domain using Certbot
# (This will automatically configure Nginx for HTTPS)
# ------------------------------------------------------------
sudo certbot --nginx -d ${DOMAIN} --email ${EMAIL} --agree-tos --no-eff-email --redirect