# Create hashtable of protocols to check
$Protocols = @{
    'SSL2.0 Server' = @{
        'Path'    = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server'
        'Default' = $true
    }
    'SSL2.0 Client' = @{
        'Path'    = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client'
        'Default' = $true
    }
    'SSL3.0 Server' = @{
        'Path'    = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server'
        'Default' = $true
    }
    'SSL3.0 Client' = @{
        'Path'    = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client'
        'Default' = $true
    }
    'TLS1.1 Server' = @{
        'Path'    = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server'
        'Default' = $true
    }
    'TLS1.1 Client' = @{
        'Path'    = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client'
        'Default' = $true
    }
    'RC4 128/128'   = @{
        'Path'    = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 128/128'
        'Default' = $true
    }
    'RC4 40/128'    = @{
        'Path'    = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 40/128'
        'Default' = $true
    }
    'RC4 56/128'    = @{
        'Path'    = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 56/128'
        'Default' = $true
    }
}

# Create output object
$output = [PSCustomObject]@{
    Host = $env:COMPUTERNAME
}

# Loop over protocol keys
foreach ($Protocol in $Protocols.Keys) {
    # Set status of the protocol to the configured default. Windows by default has them enabled (for now)
    $Status = $Protocols.$Protocol.Default

    if (Test-Path -Path $Protocols.$protocol.Path) {

        # Get the property value of the registry path's Enabled key
        $EnablePropertyValue = (Get-ItemProperty -Path $Protocols.$protocol.Path | Select-Object -ExpandProperty Enabled -ErrorAction SilentlyContinue)

        if ($EnablePropertyValue -eq "0") {
            $Status = $false
        }

        if ($EnablePropertyValue -eq "1") {
            $Status = $true
        } 
    }

    # Add this protocol name and the word Enabled along with the Status found to the output object
    Add-Member -InputObject $output -MemberType NoteProperty -Name ($Protocol + " Enabled") -value $Status
}

# Output the output object
$output