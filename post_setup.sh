#!/bin/bash
# Script to execute after the complete installation
# Possible use: clean up temporary files
echo 'Post setup script started.'
a2enmod cgid
systemctl restart apache2.service
