#!/usr/bin/bash
set -e

DEPS=(
    apache2
    certbot
    docker-compose
    docker.io
    python3-certbot-apache
)

[ "$EUID" != 0 ] && sudo -- "$0" "$@"

cat ./env

read -rp 'Are these values correct? (Ctrl-C to cancel) '

source ./env

apt update && apt upgrade
apt install "${DEPS[@]}"

for FILE in docker-compose.yaml nextcloud*.conf; do
    envsubst < "$FILE" > "$FILE"
done

cp -f nextcloud.conf /etc/apache2/sites-available
a2enmod nextcloud.conf

certbot --apache -d "$SERVER_URL"

cp -f nextcloud-le-ssl.conf /etc/apache2/sites-available

a2enmod rewrite proxy proxy_http
a2ensite nextcloud-le-ssl.conf
docker-compose up -d

echo -e '\e[32mDONE\e[0m'
