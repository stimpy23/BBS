#!/bin/bash
# v0.1

CONF="/etc/bashreq" # edit this to reflect the path to your *.conf files...

if [ -e "$1" ]
then
  rsp=$( grep -i "^ResponseList" $1 |cut -d' ' -f2- )
  req=$( grep -i "^RequestList" $1 |cut -d' ' -f2- )
  if [ -e "$req" ]
  then
    while read line
    do
      l=$( echo "$line" |tr -d '\r' )
      if [ "$( grep -v '^#' "${CONF}/magics.conf" |grep -v '^$' |grep -c "$l" )" -gt 0 ]
      then
        file="$( grep -v '^#' "${CONF}/magics.conf" |grep -v '^$' |grep "$l" |cut -d':' -f2-)"
        file="$( ls -1t "$file" 2>/dev/null |head -n1 )"
        if [ -n "$file" ]
        then
          echo "+$file" >>"$rsp"
        fi
      else
        if [ "$( grep -v '^#' "${CONF}/okfiles.conf" |grep -v '^$' |grep -c "$l" )" -gt 0 ]
        then
          echo "+$( grep -v '^#' "${CONF}/okfiles.conf" |grep -v '^$' |grep "$l" )" >>"$rsp"
        fi
      fi
    done <"$req"
  else
    echo "req-file not found"
    exit 255
  fi
else
  echo "srif-file not found"
  exit 255
fi
