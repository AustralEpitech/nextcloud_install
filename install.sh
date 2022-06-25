#!/usr/bin/bash
set -e

DEPS=(
    certbot
    docker-compose
    docker.io
    nginx
    python3-certbot-nginx
)

if [ "$EUID" != 0 ]; then
    sudo -- "$0" "$@"
    exit
fi

echo
cat ./variables.env
echo

read -rp 'Are these values correct? (Ctrl-C to cancel) '

set -a
. ./variables.env
set +a

apt update && apt upgrade -y
apt install -y "${DEPS[@]}"

envsubst "$(env | sed -e 's/=.*//' -e 's/^/$/')" < \
    nginx.conf > \
    /etc/nginx/sites-available/nextcloud

ln -sf /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/

certbot certonly -n --nginx -d "$SERVER_URL" -m "$ADMIN_MAIL" --agree-tos --test-cert

systemctl reload nginx

docker-compose up -d

echo -e '\e[32mDONE\e[0m'
