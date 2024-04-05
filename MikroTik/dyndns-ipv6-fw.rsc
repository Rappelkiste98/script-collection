#### >>> General Variables <<<
:local dmzIface "vlan100-dmz"
:local DHCPWanPool "wan-pool"
:local clients { "9ccd:e3ff:fe99:6f2a" ; "9ccd:e3ff:fe99:6f2b" }

:local listName "ipv6_global_webserver"
:local clientComment "Webserver Client"

#### >>> Functions <<<
## ==== Function "functionGetAddressFromIP" ====
:local functionGetAddressFromIP do={
    :local address

    :for i from=( [:len $ip] - 1) to=0 do={
        :if ( [:pick $ip $i] = "/") do={
            :set address [:pick $ip 0 $i]
        }
    }

    :if ([:tostr $address] = "") do={
        :set address $ip
    }

    :return ($address)
}

## ==== Function "functionGetPrefixFromIPv6" ====
:local functionGetPrefixFromIPv6 do={
    :local address

    :for i from=( [:len $ip] - 1) to=0 do={
        #:log info ("DEBUG " . [:pick $ip ($i-1)])
        :if ( ([:pick $ip $i] .  [:pick $ip ($i-1)]) = "::") do={
            :set address [:pick $ip 0 ($i-1)]
        }
    }

    :if ([:tostr $address] = "") do={
        :set address $ip
    }

    :return ($address)
}

## ==== Function "functionBuildFullClients" ====
:local functionBuildFullClients do={
    :local addressesStr

    :foreach client in=$clients do={
        :if ([:len $addressesStr] > 0) do= {
            :set $addressesStr ($addressesStr . "," . ($prefix . ":" . $client))
        } else={
            :set $addressesStr ($prefix . ":" . $client)
        }
    }

    :return ([:toarray $addressesStr])
}

#### >>> Firewall Update Process <<<
:local update false
:local dmzIP [$functionGetAddressFromIP ip=[/ipv6/address get [find interface=$dmzIface and from-pool=$DHCPWanPool] address]]
:local dmzPrefix [$functionGetPrefixFromIPv6 ip=$dmzIP]

:local fullClients [$functionBuildFullClients clients=$clients prefix=$dmzPrefix]

:foreach client in=$fullClients do={
    :if ([:len [/ipv6 firewall address-list find address=($client . "/128") comment=$clientComment]] = 0) do={
        :log info (">>> Firewall IPv6 Addresse (" . $client . ") requires Update!")
        :set update true
    }
}

:if ($update) do={
    /ipv6 firewall address-list remove [find comment=$clientComment];

    :foreach client in=$fullClients do={
        /ipv6 firewall address-list add list=$listName address=$client comment=$clientComment;
    }

    :log info (">>> Firewall IPv6 Addresses successfully Updated!")
}

#:log info ("TEST: " . $fullClients )
