#Query Registry for cipher suites

#SSLv2
$SSLv2Server = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server' -Name 'Enabled'
$SSLv2Client = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client' -Name 'Enabled'

#SSLv3
$SSLv3Server = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server' -Name 'Enabled'
$SSLv3Client = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client' -Name 'Enabled'

#TLSv1.0
$TLSv1Server = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server' -Name 'Enabled'
$TLSv1Client = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client' -Name 'Enabled'

#TLSv1.1
$TLSv1_1Server = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server' -Name 'Enabled'
$TLSv1_1Client = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client' -Name 'Enabled'


#Check if enabled

if( $SSLv2Server.Enabled -eq 0){
  $SSLv2ServerEnabled = $false
} else{
    $SSLv2ServerEnabled = $true
}

if( $SSLv2Client.Enabled -eq 0){
    $SSLv2ClientEnabled = $false
  } else{
      $SSLv2ClientEnabled = $true
}


if( $SSLv3Server.Enabled -eq 0){
    $SSLv3ServerEnabled = $false
  } else{
      $SSLv3ServerEnabled = $true
}
  
if( $SSLv3Client.Enabled -eq 0){
    $SSLv3ClientEnabled = $false
    } else{
        $SSLv3ClientEnabled = $true
}


if( $TLSv1Server.Enabled -eq 0){
    $TLSv1ServerEnabled = $false
} else{
      $TLSv1ServerEnabled = $true
}
 

if( $TLSv1Client.Enabled -eq 0){
      $TLSv1ClientEnabled = $false
} else{
        $TLSv1ClientEnabled = $true
}


if( $TLSv1_1Server.Enabled -eq 0){
    $TLSv1_1ServerEnabled = $false
} else{
      $TLSv1_1ServerEnabled = $true
}
 

if( $TLSv1_1Client.Enabled -eq 0){
      $TLSv1_1ClientEnabled = $false
} else{
        $TLSv1_1ClientEnabled = $true
}


#Report back to inventory
[PSCustomObject]@{
    
    Host = $env:COMPUTERNAME
    'SSLv2 Server Enabled' = $SSLv2ServerEnabled
    'SSLv2 Client Enabled' = $SSLv2ClientEnabled
    'SSLv3 Server Enabled' = $SSLv3ServerEnabled
    'SSLv3 Client Enabled' = $SSLv3ClientEnabled
    'TLS1.0 Server Enabled' = $TLSv1ServerEnabled
    'TLS1.0 Client Enabled' = $TLSv1ClientEnabled  
    'TLS1_1 Server Enabled' = $TLSv1_1ServerEnabled
    'TLS1_1 Client Enabled' = $TLSv1_1ClientEnabled
    
} 

