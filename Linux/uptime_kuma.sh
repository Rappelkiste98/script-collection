#!/bin/bash
host="uptime.kuma.com"
url="https://uptime.kuma.com/api/push/*******?status=up&msg=OK&ping="

pingms=$(ping -c 1 -i 1 "$host" | grep -o -E "time=[0-9]{1,3}.[0-9]" | grep -o -E "[0-9]{1,3}.[0-9]")
url+="$pingms"

curl -s -S -4 "$url"
