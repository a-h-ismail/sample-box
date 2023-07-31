#!/bin/bash
# This script executes after installing and removing the packages according to the configuration.
# Useful to build something from source to be next moved according to the files map.
if [ $EUID -ne 0 ]; then
    echo "You must run this as root, try with sudo."
    exit 1
fi
echo 'Post package install script started.'
