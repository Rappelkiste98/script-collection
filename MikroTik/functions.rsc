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
