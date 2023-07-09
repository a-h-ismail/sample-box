#!/bin/bash
su - restricted -c 'ncat -k -c "firejail --profile=/etc/firejail/only-home.profile" -l -p 40000'
