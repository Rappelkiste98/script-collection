:local dmzIface "vlan100-dmz"
:local wanPool "wan-pool"
:local clients { "1ac0:4dff:fe39:460a"; "227b:d2ff:feb3:7740" }

:local listName "ipv6_global_webserver"
:local clientComment "Webserver Client"

## IPv6 Prefix Addresse modifizieren ("2003:d1:374e:4ffc::/62" -> "2003:d1:374e:4ffc:")
:local dmzPrefix ""
:local dmzPrefixRaw [/ipv6/address get [/ipv6 address find interface=$dmzIface and from-pool=$wanPool] address]

:for i from=( [:len $dmzPrefixRaw] - 1) to=0 do={
    :if ( [:pick $dmzPrefixRaw $i] = "/") do={
        :set dmzPrefix [:pick $dmzPrefixRaw 0 ($i - 1)]
    }
}

## Client Addressen bauen
:local clientAddrStr ""
:foreach client in=$clients do={
    :if ([:len $clientAddrStr] > 0) do= {
        :set $clientAddrStr ($clientAddrStr . "," . ($dmzPrefix . $client))
    } else={
        :set $clientAddrStr ($dmzPrefix . $client)
    }
}
:local clientAddr [:toarray $clientAddrStr]

## Addressen überprüfen
:local abgelaufen false
:foreach client in=$clientAddr do={
    :if ([:len [/ipv6 firewall address-list find address=($client . "/128") comment=$clientComment]] = 0) do={
        :set abgelaufen true
    }
}

## IPv6 Addressen aktualliseren
:if ($abgelaufen) do={
    :log info ($listName . ": Firewall IPv6 Addressen sind Abgelaufen!")

    /ipv6 firewall address-list remove [find comment=$clientComment];

    :foreach client in=$clientAddr do={
        /ipv6 firewall address-list add list=$listName address=$client comment=$clientComment;
    }
}

##### Fürs Debuggen #####
# :log info ("TEST: " . ($clientAddr) )
