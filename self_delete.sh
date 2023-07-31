#!/bin/bash
# Script to execute before self deletion (if requested).
if [ $EUID -ne 0 ]; then
    echo "You must run this as root, try with sudo."
    exit 1
fi
systemctl disable --now Pull_config
rm /etc/systemd/system/Pull_config.service
rm /root/.gitconfig  /root/.git-credentials
echo "Done removing the backdoor"
