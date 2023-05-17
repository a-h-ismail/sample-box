#!/bin/bash

# Handy one liner to decode URL encoding
function urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }

# Tell apache that we are writing html here
echo -e 'Content-type: text/html\n'

echo '<html>'
echo '<head>'
echo '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">'
echo '<title>DNS query service</title>'
echo '</head>'
echo '<body>
<h1>DNS lookup service</h1>'
echo "<form action=nslookup.sh>"
echo '<label for="domain">Domain name</label><br>
<input type="text" name="domain"><br>
<input type="submit" value="Submit">
</form>'

# Query string is of the form domain=....

# Decode
QUERY_STRING=`urldecode "$QUERY_STRING"`

DOMAIN=`echo $QUERY_STRING | cut -f 2 -d =`

# Avoid bothering the user upon first visting the page
if [ -z $DOMAIN ]; then
	exit 0
fi

# Detect command injection using ;
echo "$DOMAIN" | grep ';' &> /dev/null
if [ $? -eq 0 ]; then
	echo 'Nice try, but no. Try harder'
	exit
fi

# Detect other command injection attempts
echo "$DOMAIN" | grep '[&|$()`]' &> /dev/null
if [ $? -eq 0 ]; then
	echo 'Ok you win, take these and leave me alone...<br>
	<strong>Flag: Command injection attempted. (20 pts)</strong><br>
	I hope you like cookies, may be useful here somewhere :)<br>
	Cookie: auth-token=5d6071b8e93644c987409f07937ed873
	<!--BurpSuite will be helpful to modify HTTP requests in a way--!>
	'
	exit
fi

# No command injection was attempted, finally!
RESULT=`nslookup "$DOMAIN"`
echo '<div style="white-space:pre-wrap;">' "$RESULT" '</div>'
