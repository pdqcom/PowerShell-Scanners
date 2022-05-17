#Query Registry for transport protocols

#SSLv2
$SSLv2Server = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server'
$SSLv2Client = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client' 

#SSLv3
$SSLv3Server = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server' 
$SSLv3Client = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client' 

#TLSv1.0
$TLSv1Server = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server' 
$TLSv1Client = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client' 

#TLSv1.1
$TLSv1_1Server = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server' 
$TLSv1_1Client = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client' 

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
}
$output = [PSCustomObject]@{
    Host = $env:COMPUTERNAME
}
foreach ($Protocol in $Protocols.Keys) {
    $Status = $Protocols.$Protocol.Default
    if (Test-Path -Path $Protocols.$protocol.Path) {
        $EnablePropertyValue = (Get-ItemProperty -Path $Protocols.$protocol.Path | Select-Object -ExpandProperty Enabled -ErrorAction SilentlyContinue)
        if ($EnablePropertyValue -eq "0") {
            $Status = $false
        }
        if ($EnablePropertyValue -eq "1") {
            $Status = $true
        } 
    }
    Add-Member -InputObject $output -MemberType NoteProperty -Name ($Protocol + " Enabled") -value $Status
}

$output