#!/bin/bash

# Config ab hier:
interface="wgvpn_test" # Name der Schnittstelle, die geprueft werden soll
domain="test.domain.de" # Domain des Peers, dessen IP geprueft werden soll

# Programmablauf ab hier:
wgIP4=$(wg show $interface endpoints | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
wgIP6=$(wg show $interface endpoints | grep -E -o "([0-9a-f]{1,4}[:]){2,7}[0-9a-f]{1,4}")
wgHandshakeDiff=$[ $(date +%s) - $(wg show $interface latest-handshakes | grep -E -o "[0-9]{10,99}") ]
echo "wg IPv4: $wgIP4"
echo "wg IPv6: $wgIP6"
echo "wg Handshake Diff: $wgHandshakeDiff"

digIP4=$(dig +short $domain A)
digIP6=$(dig +short $domain AAAA)
echo "dig IPv4: $digIP4"
echo "dig IPv6: $digIP6"

if [ ! -z "$wgIP4" ] && [ ! -z "$digIP4" ]; then
        if [ "$digIP4" != "$wgIP4" ]; then
                echo "IPv4 Adressen unterscheiden sich! Interface wird neu gestartet!"
                /usr/sbin/service wg-quick@$interface restart
                exit 0
        fi
fi

if [ ! -z "$wgIP6" ] && [ ! -z "$digIP6" ]; then
        if [ "$digIP6" != "$wgIP6" ]; then
                 echo "IPv6 Adressen unterscheiden sich! Interface wird neu gestartet!"
                /usr/sbin/service wg-quick@$interface restart
                exit 0
        fi
fi

if { { [ -z "$wgIP4" ] && [ ! -z "$digIP4" ]; } || { [ -z "$wgIP6" ] && [ -n "$digIP6" ]; } } && (( $wgHandshakeDiff > 300 )); then
        echo "Interface fehlerhaft, letzter Handshake laenger als 5min! Interface wird neu gestartet!"
        /usr/sbin/service wg-quick@$interface restart
        exit 0
fi
