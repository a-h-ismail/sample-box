#!/bin/bash
while true
do
  echo "Hint is in the port number: V2VsbCB0aG91Z2h0IQpGbGFnOiBDaGFuZ2luZyBlbmNvZGluZyBpcyBub3QgZW5jcnlwdGlvbiwgb2s/IC0gMTUgcG9pbnRz" | nc -l -p 20064
  sleep 1
done
