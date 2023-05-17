#!/bin/bash
while true
do
  echo "Flag: I do full scans – 10 points" | nc -l -p 36111
  sleep 1
done
