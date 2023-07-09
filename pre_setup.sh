#!/bin/bash
# Add commands to execute before the main setup script
# For example: use to setup additional repositories.
echo 'Pre setup script started.'
# Add users
useradd webadmin -m -p '$6$nCOik.D2VK77fc6X$OHsS8Vs4EUm7x67mKdJrtbcgIBSrWCJDVdrVt2tbCYZqa9.62otHSl31U4E83AuejpPCmisUFq8Zhk/iJvjmW/'
usermod -aG sudo webadmin
useradd restricted -m
chmod -R 744 /home/restricted
chown -R root /home/restricted
chgrp -R root /home/restricted
