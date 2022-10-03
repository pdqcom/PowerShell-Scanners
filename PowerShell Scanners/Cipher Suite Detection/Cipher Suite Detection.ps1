# Create hashtable of protocols to check
$Protocols = @{
    'SSL2.0 Server' = @{
        'Path'    = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server'
        'Default' = "OS Default"
    }
    'SSL2.0 Client' = @{
        'Path'    = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client'
        'Default' = "False"
    }
    'SSL3.0 Server' = @{
        'Path'    = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server'
        'Default' = "OS Default"
    }
    'SSL3.0 Client' = @{
        'Path'    = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client'
        'Default' = "OS Default"
    }
    'TLS1.0 Server' = @{
        'Path'    = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server'
        'Default' = "True"
    }
    'TLS1.0 Client' = @{
        'Path'    = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client'
        'Default' = "True"
    }
    'TLS1.1 Server' = @{
        'Path'    = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server'
        'Default' = "OS Default"
    }
    'TLS1.1 Client' = @{
        'Path'    = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client'
        'Default' = "OS Default"
    }
    'RC4 128/128'   = @{
        'Path'    = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 128/128'
        'Default' = "OS Default"
    }
    'RC4 40/128'    = @{
        'Path'    = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 40/128'
        'Default' = "OS Default"
    }
    'RC4 56/128'    = @{
        'Path'    = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 56/128'
        'Default' = "OS Default"
    }
}

# Create output object
$output = [PSCustomObject]@{
    Host = $env:COMPUTERNAME
}

# Loop over protocol keys
foreach ($Protocol in $Protocols.Keys) {
    $Status = $Protocols.$Protocol.Default

    if (Test-Path -Path $Protocols.$protocol.Path) {

        # Get the property value of the registry path's Enabled key
        # 4294967295 is the decimal equivalent of 0xffffffff. See https://www.nartac.com/Products/IISCrypto/FAQ/Why-does-iis-crypto-set-the-protocols-enabled-value-to-0xffffffff
        $EnablePropertyValue = (Get-ItemProperty -Path $Protocols.$protocol.Path | Select-Object -ExpandProperty Enabled -ErrorAction SilentlyContinue)

        if ($EnablePropertyValue -eq "0") {
            $Status = "False"
        }

        if (($EnablePropertyValue -eq "1") -or ($EnablePropertyValue -eq "4294967295")) {
            $Status = "True"
        }
    }

    # Add this protocol name and the word Enabled along with the Status found to the output object
    Add-Member -InputObject $output -MemberType NoteProperty -Name ($Protocol + " Enabled") -value $Status
}

# Output the output object
$output