#Query Registry for cipher suites

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


#Check if enabled

if (Test-Path -Path $SSLv2Server) {

    if ((Get-ItemPropertyValue -Path $SSLv2Server -Name Enabled -ErrorAction SilentlyContinue) -eq "0") {
        $SSLv2ServerEnabled = $false
    }

    if ((Get-ItemPropertyValue -Path $SSLv2Server -Name Enabled -ErrorAction SilentlyContinue) -eq "1") {
        $SSLv2ServerEnabled = $true
    }

} elseif(-Not (Test-Path -Path $SSLv2Server)){
    $SSLv2ServerEnabled = "Key not found in registry."
} else {
    $SSLv2ServerEnabled = "Unknown issue occured. Requires manual review."
}


if(Test-Path -Path $SSLv2Client){

    if((Get-ItemPropertyValue -Path $SSLv2Client -Name Enabled -ErrorAction SilentlyContinue) -eq "0"){
        $SSLv2ClientEnabled = $false
    }

    if((Get-ItemPropertyValue -Path $SSLv2Client -Name Enabled -ErrorAction SilentlyContinue) -eq "1"){
        $SSLv2ClientEnabled = $true
    }

} elseif(-Not (Test-Path -Path $SSLv2Client)){
    $SSLv2ClientEnabled = "Key not found in registry"
} else{
      $SSLv2ClientEnabled = "Unknown issue occured. Requires manual review."
}

if(Test-Path -Path $SSLv3Server){

    if((Get-ItemPropertyValue -Path $SSLv3Server -Name Enabled -ErrorAction SilentlyContinue) -eq "0"){
        $SSLv3ServerEnabled = $false
    }

    if((Get-ItemPropertyValue -Path $SSLv3Server -Name Enabled -ErrorAction SilentlyContinue) -eq "1"){
        $SSLv3ServerEnabled = $true
    }

} elseif(-Not (Test-Path $SSLv3Server)){
    $SSLv3ServerEnabled = "Key not found in registry"
} else{
      $SSLv3ServerEnabled = "Unknown issue occured. Requires manual review."
}

if(Test-Path -Path $SSLv3Client){

    if( (Get-ItemPropertyValue -Path $SSLv3Client -Name Enabled -ErrorAction SilentlyContinue) -eq "0"){
        $SSLv3ClientEnabled = $false
    }

    if( (Get-ItemPropertyValue -Path $SSLv3Client -Name Enabled -ErrorAction SilentlyContinue) -eq "1"){
        $SSLv3ClientEnabled = $true
    }

} elseif(-Not (Test-Path -Path $SSLv3Client)){
    $SSLv3ClientEnabled = "Key not found in registry"
} else{
        $SSLv3ClientEnabled = "Unknown issue occured. Requires manual review."
}

if(Test-Path -Path $TLSv1Server){

    if((Get-ItemPropertyValue -Path $TLSv1Server -Name Enabled -ErrorAction SilentlyContinue) -eq "0"){
        $TLSv1ServerEnabled = $false
    }

    if((Get-ItemPropertyValue -Path $TLSv1Server -Name Enabled -ErrorAction SilentlyContinue) -eq "1"){
        $TLSv1ServerEnabled = $true
    }

} elseif(-Not (Test-Path -Path $TLSv1Server)){
    $TLSv1ServerEnabled = "Key not found in registry"
} else{
      $TLSv1ServerEnabled = "Unknown issue occured. Requires manual review."
}
 
if(Test-Path -Path $TLSv1Client){

    if((Get-ItemPropertyValue -Path $TLSv1Client -Name Enabled -ErrorAction SilentlyContinue) -eq "0"){
        $TLSv1ClientEnabled = $false
    }

    if((Get-ItemPropertyValue -Path $TLSv1Client -Name Enabled -ErrorAction SilentlyContinue) -eq "1"){
        $TLSv1ClientEnabled = $true
    }

} elseif(-Not (Test-Path -Path $TLSv1Client)){
    $TLSv1ClientEnabled = "Key not found in registry"
} else{
        $TLSv1ClientEnabled = "Unknown issue occured. Requires manual review."
}

if(Test-Path -Path $TLSv1_1Server){

    if((Get-ItemPropertyValue -Path $TLSv1_1ServerEnabled -Name Enabled -ErrorAction SilentlyContinue) -eq "0"){
        $TLSv1_1ServerEnabled = $false
    }

    if((Get-ItemPropertyValue -Path $TLSv1_1ServerEnabled -Name Enabled -ErrorAction SilentlyContinue) -eq "1"){
        $TLSv1_1ServerEnabled = $true
    }

} elseif(-Not (Test-Path -Path $TLSv1_1Server)){
    $TLSv1_1ServerEnabled = "Key not found in registry"
} else{
      $TLSv1_1ServerEnabled = "Unknown issue occured. Requires manual review."
}
 
if(Test-Path -Path $TLSv1_1Client){

    if((Get-ItemPropertyValue -Path $TLSv1_1Client -Name Enabled -ErrorAction SilentlyContinue) -eq "0"){
        $TLSv1_1ClientEnabled = $false
    }

    if((Get-ItemPropertyValue -Path $TLSv1_1Client -Name Enabled -ErrorAction SilentlyContinue) -eq "1"){
        $TLSv1_1ClientEnabled = $true
    }


} elseif(-Not (Test-Path -Path $TLSv1_1Client)){
    $TLSv1_1ClientEnabled ="Key not found in registry"
} else{
        $TLSv1_1ClientEnabled = "Unknown issue occured. Requires manual review."
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

