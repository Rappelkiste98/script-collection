#### >>> General Variables <<<
:local wanIface "ether1"
:local domain "test.domain.de"
# "https://ipv64.net/nic/update?key=<key>&domain=<domain>&ip=<ipaddr>&ip6=<ip6addr>&ip6lanprefix=<ip6lanprefix>"
:local url "https://ipv64.net/nic/update?key=<key>&domain=<domain>&ip=<ipaddr>&ip6=<ip6addr>&ip6lanprefix=<ip6lanprefix>"
:local key "z0u6ibyvJ47sBkQRtfKox1pNnXLC5haZ"

#### >>> IPv6 Variables <<<
:local DHCPWanPool "wan-pool"
:local prefixIface "vlan100-dmz"

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
        :if ( ([:pick $ip $i] .  [:pick $ip ($i-1)]) = "::") do={
            :set address [:pick $ip 0 ($i-1)]
        }
    }

    :if ([:tostr $address] = "") do={
        :set address $ip
    }

    :return ($address)
}

## ==== Function "functionGetPrefixLengthFromIPv6" ====
:local functionGetPrefixLengthFromIPv6 do={
    :local prefixLength

    :for i from=( [:len $ip] - 1) to=0 do={
        :if ( [:pick $ip $i] = "/") do={
            :set prefixLength [:pick $ip ($i+1) [:len $ip]]
        }
    }

    :if ([:tostr $prefixLength] = "") do={
        :set prefixLength 128
    }

    :return ($prefixLength)
}

## ==== Function "functionResolveDNS" ====
:local functionResolveDNS do={
    :local ip

    :if ($type = "A") do={
        /ip/firewall/address-list
        
        :do {
            add address=$domain list="Auto: ResolveDNS"
            :delay 1000ms
        } on-error={ };
        :set ip [get [:pick [find list="Auto: ResolveDNS" dynamic] ([:len [find list="Auto: ResolveDNS" dynamic]]-1)] address]
        remove [find list="Auto: ResolveDNS" !dynamic]
    } else={
        /ipv6/firewall/address-list

       :do {
            add address=$domain list="Auto: ResolveDNS"
            :delay 1000ms
        } on-error={ };
        :set ip [get [:pick [find list="Auto: ResolveDNS" dynamic] ([:len [find list="Auto: ResolveDNS" dynamic]]-1)] address]
        remove [find list="Auto: ResolveDNS" !dynamic]
    }

    :return ($ip)
}

## ==== Function "functionReplaceUrlParam" ====
:local functionReplaceUrlParam do={
    :local newUrl

    :local i [:find $url $param -1]
    :set newUrl ([:pick $url 0 $i] . $value . [:pick $url ($i + [:len $param]) [:len $url]])

    :return $newUrl
}

#### >>> Domain Update Process <<<
:local update false
:local updateUrl [$functionReplaceUrlParam url=$url param="<key>" value=$key]
:set updateUrl [$functionReplaceUrlParam url=$updateUrl param="<domain>" value=$domain]

:local wanIPv4
:local domainIPv4
:if ([:tobool [:find $url "<ipaddr>" -1]]) do={
    :set wanIPv4 [$functionGetAddressFromIP ip=[/ip/address get [find interface=$wanIface] address]]
    :set domainIPv4 [$functionGetAddressFromIP ip=[$functionResolveDNS type=A domain=$domain]]

    :if (($wanIPv4 != $domainIPv4) && ([:tostr $wanIPv4] != [:tostr $ddnsIPv4])) do={
        :global ddnsIPv4 $wanIPv4
        :set update true
        :log info (">>> dynDNS || Update IPv4: $domainIPv4 -> $wanIPv4")
    }
    :set updateUrl [$functionReplaceUrlParam url=$updateUrl param="<ipaddr>" value=$wanIPv4]
}

:local wanIPv6
:local domainIPv6
:if ([:tobool [:find $url "<ip6addr>" -1]]) do={
    :set wanIPv6 [$functionGetAddressFromIP ip=[/ipv6/address get [find interface=$wanIface !link-local] address]]
    :set domainIPv6 [$functionGetAddressFromIP ip=[$functionResolveDNS type=AAAA domain=$domain]]

    if (($wanIPv6 != $domainIPv6) && ([:tostr $wanIPv6] != [:tostr $ddnsIPv6])) do={
        :global ddnsIPv6 $wanIPv6
        :set update true
        :log info (">>> dynDNS || Update IPv6: $domainIPv6 -> $wanIPv6")
    }
    :set updateUrl [$functionReplaceUrlParam url=$updateUrl param="<ip6addr>" value=$wanIPv6]
}

:local wanIPv6Prefix
:if ([:tobool [:find $url "<ip6lanprefix>" -1]]) do={
    :local wanPrefixRaw [/ipv6/address get [find interface=$prefixIface and from-pool=$DHCPWanPool] address]
    :set wanIPv6Prefix ([$functionGetPrefixFromIPv6 ip=$wanPrefixRaw] . "::/" . [$functionGetPrefixLengthFromIPv6 ip=$wanPrefixRaw])
    :log info (">>> dynDNS || Update IPv6-Prefix: ? -> $wanIPv6Prefix")

    :set updateUrl [$functionReplaceUrlParam url=$updateUrl param="<ip6lanprefix>" value=$wanIPv6Prefix]
}

## DynDNS Service aufrufen
:if ($update) do={
    /tool fetch url=$updateUrl mode=https keep-result=no
    :log info (">>> dynDNS || Domain successfully Updated!")
    #:log warning ($updateUrl)
}
