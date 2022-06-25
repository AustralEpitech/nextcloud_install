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

read -rp 'Are these values correct? (Ctrl-C to cancel)'

set -a
. ./variables.env
set +a

apt update && apt upgrade -y
apt install -y "${DEPS[@]}"

docker-compose up -d

# find config.php path
NC_CONFIG_FILE="$(sudo docker volume inspect nextcloud_config | jq '.[].Mountpoint')"

# generate append default options to config.php
head -n -1 "$NC_CONFIG_FILE" > tmp
cat config.php >> tmp
cat tmp > "$NC_CONFIG_FILE"
rm tmp

# install nextcloud nginx config
envsubst "$(env | sed -e 's/=.*//' -e 's/^/$/')" < \
    nextcloud_nginx > \
    /etc/nginx/sites-available/nextcloud

ln -sf /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/

certbot certonly -n --nginx -d "$SERVER_URL" -m "$ADMIN_MAIL" --agree-tos --test-cert

systemctl restart nginx

echo -e '\e[32mDONE\e[0m'
