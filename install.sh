#!/usr/bin/bash
set -e

CP="cp -f"

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

apt update && apt upgrade -y
apt install -y "${DEPS[@]}"

for FILE in nextcloud*.conf; do
    envsubst < "$FILE" > "$FILE"
done

$CP nextcloud.conf /etc/apache2/sites-available

certbot certonly -n --apache -d "$SERVER_URL" -m "$SERVER_MAIL" --agree-tos --test-cert

$CP nextcloud-le-ssl.conf /etc/apache2/sites-available

a2enmod rewrite proxy proxy_http
a2ensite nextcloud.conf nextcloud-le-ssl.conf
docker-compose up -d

echo -e '\e[32mDONE\e[0m'
