#!/usr/bin/bash
set -xe

SQL_LOGIN="${SQL_LOGIN-'username'}"
SQL_PASSWD="${SQL_PASSWD-'password'}"
SERVER_NAME="${SERVER_NAME-'your.server.com'}"

DEPS=(
    apache2
    certbot
    python3-certbot-apache
    mariadb-server
    libapache2-mod-php
    php-gd
    php-mysql
    php-curl
    php-mbstring
    php-intl
    php-gmp
    php-bcmath
    php-xml
    php-imagick
    php-zip
)

ARCHIVE_NAME=latest.tar.bz2

# install dependencies
apt update
apt upgrade
apt install "$(DEPS[@])"

# go to a temporary directory
cd "$(mktemp -d)"

# retrieve latest stable release
wget "https://download.nextcloud.com/server/releases/$ARCHIVE_NAME"
tar xvf "$ARCHIVE_NAME"

# initialize mariadb
echo "CREATE USER '$SQL_LOGIN'@'localhost' IDENTIFIED BY '$SQL_PASSWD';
CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
GRANT ALL PRIVILEGES ON nextcloud.* TO '$SQL_LOGIN'@'localhost';
FLUSH PRIVILEGES;" | mysql

# copy nextcloud data to system directory
mkdir -p /var/www
cp -r nextcloud /var/www

chown -R www-data:www-data /var/www/nextcloud

############################
### APACHE CONFIGURATION ###
############################
# create config file
(
    cd /etc/apache2/sites-available
    wget https://raw.githubusercontent.com/AustralEpitech/nextcloud_install/main/nextcloud.conf
    sed -i "s/%%SERVER_NAME%%/$SERVER_NAME/g" nextcloud.conf


    # enable ssl
    certbot --apache -d "$SERVER_NAME"

    if [ ! -f 'nextcloud-le.conf' ]; then
        wget https://raw.githubusercontent.com/AustralEpitech/nextcloud_install/main/nextcloud-le-ssl.conf
        sed -i "s/%%SERVER_NAME%%/$SERVER_NAME/g" nextcloud-le-ssl.conf
    fi
)

# enable config file
a2ensite nextcloud.conf nextcloud-le-ssl.conf

# enable required modules
a2enmod rewrite headers env dir mime ssl
systemctl restart apache2
