#!/bin/sh

# Exit immediately if a command exits with a non-zero status.
set -e

# directing binary data stream from post request to that file
dd of=../uploads/profile.png
# if the above isn't working you may try
# cat /dev/stdin > ..$sanitized

echo 'Content-type: text/html'
echo ''
echo 'File upload successful, redirecting...
'
