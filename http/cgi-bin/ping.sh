#!/bin/bash

function urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }

echo -e "Content-type: text/html\n"

echo '<html>'
echo '<head>'
echo '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">'
echo '<title>Latency test</title>'
echo '</head>'
echo '<body>
<h1>Enter the number of pings used for latency testing:</h1>
<form action="ping.sh">
<label for="count">Number of pings</label>
<input id="count" name="count" type="text">
<input type="submit" value="Run!">
</form>
'

if [ -n "$QUERY_STRING" ]; then
    $QUERY_STRING=`urldecode "$QUERY_STRING"`
    COUNT=`echo "$QUERY_STRING" | cut -f 2 -d =`
    # Check if the count is actually only numbers
    if [[ "$COUNT" =~ ^[0-9]+$ ]]; then
        RESULT=`ping $REMOTE_ADDR -c $COUNT`
        echo -e "<div style='white-space:pre-wrap;'><tt>\n$RESULT\n</tt></div>"
    else
        echo "Invalid count parameter"
    fi
fi
echo '</body></html>'