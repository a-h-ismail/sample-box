#!/bin/bash

# Handy one liner to decode URL encoding (thanks stackoverflow)
function urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }

# Tell apache that we are writing html here
echo -e "Content-type: text/html\n"

echo '<html>'
echo '<head>'
echo '<title>Login page</title>'
echo '</head>
<body>
<h1>Enter your credentials</h1>
<form action=admin.sh method="post">
<label for="username">Username</label><br>
<input type="text" name="username"><br>
<label for="password">Password</label><br>
<input type="text" name="password"><br>
<input type="submit" value="login">
</form>
</body>
</html>'
