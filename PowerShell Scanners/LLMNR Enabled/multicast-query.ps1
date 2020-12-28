
$Multicast = Get-ItemProperty -Path 'HKLM:SOFTWARE\Policies\Microsoft\Windows NT\DNSClient\' -Name 'EnableMulticast'


if( $Multicast.EnableMultiCast -eq 0){
  $Enabled = $false
} else{
    $Enabled = $true
}

[PSCustomObject]@{
    Host = $env:COMPUTERNAME
    Enabled  = $Enabled
    PSPath = $Multicast.PSPath
} 