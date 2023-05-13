#!/bin/bash
function urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }

AUTHENTICATED="no"
AUTH_TOKEN=`echo $HTTP_COOKIE | cut -f 2 -d =`
# Check if the user is already authenticated
if [ $AUTH_TOKEN = '5d6071b8e93644c987409f07937ed873' ]; then
    AUTHENTICATED="yes"
else
    if [ "$REQUEST_METHOD" = "POST" ]; then
        # Read the query from stdin and decode it
        QUERY=`cat`
        QUERY=`urldecode "$QUERY"`
        
        # format: username=...&password=...
        USERNAME=`echo $QUERY | cut -f 1 -d \& | grep -w 'username' | cut -f 2 -d =`
        PASS=`echo $QUERY | cut -f 2 -d \& | grep -w 'password' | cut -f 2 -d =`

        RESULT=`/usr/bin/mysql -h localhost -u web_user -e "USE web_service; SELECT username FROM creds WHERE username IN ( '$USERNAME' ) AND password IN ( '$PASS' ) LIMIT 1;"`
        if [ -n $RESULT ]; then
            AUTHENTICATED="yes"
            echo -e 'Set-Cookie:auth-token=5d6071b8e93644c987409f07937ed873; max-age=86400;'
        fi
    fi
fi

echo -e "Content-type: text/html\n"
echo '<html>'
echo '<head>'
echo '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">'
echo '<title>Administration page</title>'
echo '</head>'
echo '<body>'
if [ $AUTHENTICATED = "yes" ]; then
    echo '<h1>Admin dashboard</h1><br>
    <h2>Profile photo</h2><img src="../uploads/profile.png"><br>

