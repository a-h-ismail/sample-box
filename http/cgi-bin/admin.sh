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
		# tr removes the trailing newline as it is messing the base64 encoding
		# Encoding in base64 is an effective mitigation for SQL injection
		USERNAME=`echo $QUERY | cut -f 1 -d \& | grep -w 'username' | cut -f 2 -d = | tr -d '\n' | base64`
		PASS=`echo $QUERY | cut -f 2 -d \& | grep -w 'password' | cut -f 2 -d = | tr -d '\n' | base64`

		RESULT=`/usr/bin/mysql -h localhost -u web_user -e "USE web_service;
		SELECT username FROM creds WHERE username IN ( FROM_BASE64('$USERNAME') ) AND password IN ( FROM_BASE64('$PASS') ) LIMIT 1;"`

		if [ -n "$RESULT" ]; then
			AUTHENTICATED="yes"
			echo 'Set-Cookie:auth-token=5d6071b8e93644c987409f07937ed873; max-age=86400;'
		fi
    fi
fi

echo -e "Content-type: text/html\n"
echo '<html>'
echo '<head>'
echo '<title>Administration page</title>'

if [ "$AUTHENTICATED" = "yes" ]; then
	echo '</head>
	<body>
	<h1>Admin dashboard</h1>
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
			if [ -n "$RESULT" ]; then
				echo -e "<div style='white-space:pre-wrap;'><tt>\n$RESULT\n</tt></div>"
			else
				echo -e "<div style='white-space:pre-wrap;'><tt>\nID doesn't match any user\n</tt></div>"
			fi
		fi
	fi
else
	echo '<meta http-equiv="refresh" content="3; URL=./login.sh" ></head>
	<body>Access denied. try again...<br>
	Redirecting in 3 seconds.</body>
	</html>'
fi
