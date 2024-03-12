#!/bin/bash
# Config ab hier:
interface="wgvpn0" # Name der Schnittstelle, die geprueft werden soll
domain="wireguard.vpn.com" # Domain des Peers, dessen IP geprueft werden soll


# Programmablauf ab hier:
cip4=$(wg show $interface endpoints | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
cip6=$(wg show $interface endpoints | grep -E -o "([0-9a-f]{1,4}[:]){1,7}[0-9a-f]{1,4}")

digIP4=$(dig +short $domain A)
digIP6=$(dig +short $domain AAAA)

echo "IPv4 | wirguard: $cip4 dns: $digIP4\n"
echo "IPv6 | wirguard: $cip6 dns: $digIP6\n"

if [ ! -z "$cip4" -a ! -z "$digIP4" ]
then
        if [ "$digIP4" != "$cip4" ]
        then
                echo "IPv4 Adressen unterscheiden sich! Interface wird neu gestartet!"
                /usr/sbin/service wg-quick@$interface restart
                exit 0
        fi
fi

if [ ! -z "$cip6" -a ! -z "$digIP6" ]
then
        if [ "$digIP6" != "$cip6" ]
        then
                 echo "IPv6 Adressen unterscheiden sich! Interface wird neu gestartet!"
                /usr/sbin/service wg-quick@$interface restart
                exit 0
        fi
fi