#!/bin/bash
function urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }

AUTHENTICATED="no"
AUTH_TOKEN=`echo $HTTP_COOKIE | grep -w 'auth-token' | cut -f 2 -d =`

# Check if the user is already authenticated
# Hardcoding tokens is a terrible idea, which is the goal of a vulnerable VM, right?
if [ "$AUTH_TOKEN" = '5d6071b8e93644c987409f07937ed873' ]; then
    AUTHENTICATED="yes"
else
	if [ "$REQUEST_METHOD" = "POST" ]; then
    	# Read the query from stdin and decode it
    	QUERY=`cat`
		QUERY=`urldecode "$QUERY"`
        
		# format: username=...&password=...
		# The first cut isolates the query parameter, grep makes sure we are getting the expected parameter, the last cut gets the value
		USERNAME=`echo $QUERY | cut -f 1 -d \& | grep -w 'username' | cut -f 2 -d =`
		PASS=`echo $QUERY | cut -f 2 -d \& | grep -w 'password' | cut -f 2 -d =`

		RESULT=`/usr/bin/mysql -h localhost -u web_user -e "USE web_service; SELECT username FROM creds WHERE username IN ( '$USERNAME' ) AND password IN ( '$PASS' ) LIMIT 1;"`

		if [ -n "$RESULT" ]; then
			AUTHENTICATED="yes"
			echo -e 'Set-Cookie:auth-token=5d6071b8e93644c987409f07937ed873; max-age=86400;'
		fi
    fi
fi

echo -e "Content-type: text/html\n"
echo '<html>'
echo '<head>'
echo '<title>Administration page</title>'
echo '</head>'

if [ "$AUTHENTICATED" = "yes" ]; then
	echo '<body>
	<h1>Admin dashboard</h1><br>
	The page is still a work in progress.<br>

	<h2>Query user ID</h2>
	<form action=admin.sh>
	<label for="id">User ID</label><br>
	<input type="text" name="id"><br>
	<input type="submit" value="Go!">
	</form>'

	# Sending the query using GET (POST is already used for authentication)
	if [ "$REQUEST_METHOD" = "GET" ]; then
		QUERY_STRING=`urldecode $QUERY_STRING`
		ID=`echo "$QUERY_STRING" | grep -w 'id' | cut -f 2 -d =`
		if [ -n "$ID" ]; then
			RESULT=`/usr/bin/mysql -t -h localhost -u web_user -e "USE web_service; SELECT * FROM creds WHERE ID = $ID;"`
			echo -e "<div style='white-space:pre-wrap;'><tt>\n$RESULT\n</tt></div>"
		fi
	fi
else
	echo "Access denied."
fi
