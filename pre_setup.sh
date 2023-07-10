#!/bin/bash
# Add commands to execute before the main setup script
# For example: use to setup additional repositories.
if [ $EUID -ne 0 ]; then
    echo "You must run this as root, try with sudo."
    exit 1
fi
echo 'Pre setup script started.'
# Add users
useradd webadmin -m -p '$y$j9T$1ubTgk7MJvNnS190ILzCV1$yuR1/M8zRtg6YbH6MCjSwUNw.y9aigWiLO6EjJenUE9' -s /bin/bash
usermod -aG sudo webadmin
useradd restricted -m -s /bin/bash
chmod -R 755 /home/restricted
chown -R root /home/restricted
chgrp -R root /home/restricted
