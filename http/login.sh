#!/bin/bash

# Handy one liner to decode URL encoding (thanks stackoverflow)
function urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }

# Tell apache that we are writing html here
echo "Content-type: text/html"

echo '<html>'
echo '<head>'
echo '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">'
echo '<title>Test SQL query</title>'
echo '</head>
<body>
<h1>Simple form query using GET method</h1>
<form action=login.cgi>
<label for="username">Username</label><br>
<input type="text" name="username"><br>
<label for="password">Password</label><br>
<input type="text" name="password"><br>
<input type="submit" value="login">
</form>'
