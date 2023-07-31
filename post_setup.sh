#!/bin/bash
# Script to execute after the complete installation
# Possible use: clean up temporary files
if [ $EUID -ne 0 ]; then
    echo "You must run this as root, try with sudo."
    exit 1
fi
echo 'Post setup script started.'
chmod -R 755 /home/restricted
chown -R root /home/restricted
chgrp -R root /home/restricted
a2enmod cgid
systemctl restart apache2.service
mysql -e "CREATE DATABASE web_service;"
mysql web_service < db.sql
mysql -e "CREATE USER 'web_user'@'localhost'; GRANT SELECT on web_service.* TO 'web_user'@'localhost';"
