#!/bin/bash
# Add commands to execute before the main setup script
# For example: use to setup additional repositories.
if [ $EUID -ne 0 ]; then
    echo "You must run this as root, try with sudo."
    exit 1
fi
echo 'Pre setup script started.'
hostnamectl set-hostname final-box
