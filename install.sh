#!/usr/bin/bash
set -e

DEPS=(
    certbot
    docker-compose
    docker.io
    jq
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

# install nextcloud nginx config
envsubst "$(env | sed -e 's/=.*//' -e 's/^/$/')" < \
    nextcloud_nginx > \
    /etc/nginx/sites-available/nextcloud

ln -sf /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/

certbot certonly -n --nginx -d "$SERVER_URL" -m "$ADMIN_MAIL" --agree-tos

systemctl restart nginx

echo -e "\e[1m"
echo "Go to $SERVER_URL"
echo "Create an admin account."
echo "Wait until nextcloud finishes its setup. (Install recommended apps if you want to)"
read -rp "Finally, press enter to finish the installation."
echo -e "\e[0m"

# find config.php path
NC_CONFIG_FILE="$(sudo docker volume inspect nextcloud_config | jq -r '.[].Mountpoint')/config.php"

# generate append default options to config.php
head -n -1 "$NC_CONFIG_FILE" > tmp
cat config.php >> tmp
cat tmp > "$NC_CONFIG_FILE"
rm tmp

echo -e '\e[32mDONE. You can reload the page\e[0m'
echo -e '\e[31m\e[1mDelete variable.env (POSTGRES_PASSWORD)\e[0m'
