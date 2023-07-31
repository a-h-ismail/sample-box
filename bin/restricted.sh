#!/bin/bash
kill -9 $(lsof -Pi :40000 -sTCP:LISTEN -t)
su - restricted -c 'ncat -k -c "firejail --profile=/etc/firejail/only-home.profile" -l -p 40000'
