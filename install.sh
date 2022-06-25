#!/usr/bin/bash
set -e

DEPS=(
    apache2
    certbot
    docker-compose
    docker.io
    python3-certbot-apache
)

if [ "$EUID" != 0 ]; then
    sudo -- "$0" "$@"
    exit
fi

echo
cat ./env
echo

read -rp 'Are these values correct? (Ctrl-C to cancel) '

set -a
. ./env
set +a

apt update && apt upgrade -y
apt install -y "${DEPS[@]}"

envsubst < nextcloud.conf > /etc/apache2/sites-available/nextcloud.conf

certbot certonly -n --apache -d "$SERVER_URL" -m "$SERVER_MAIL" --agree-tos --test-cert

envsubst < nextcloud-le-ssl.conf > /etc/apache2/sites-available/nextcloud-le-ssl.conf

a2enmod rewrite proxy proxy_http
a2ensite nextcloud.conf nextcloud-le-ssl.conf

systemctl reload apache2

docker-compose up -d

echo -e '\e[32mDONE\e[0m'
