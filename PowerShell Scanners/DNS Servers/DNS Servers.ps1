Foreach ( $Interface in (Get-NetIPConfiguration) ) {

    $Order = 1

    Foreach ( $DnsServer in $Interface.DNSServer.ServerAddresses ) {

        [PSCustomObject]@{
            'Interface Alias' = $Interface.InterfaceAlias
            'DNS Server'      = $DnsServer
            'Order'           = $Order
        }

        $Order ++

    }

}