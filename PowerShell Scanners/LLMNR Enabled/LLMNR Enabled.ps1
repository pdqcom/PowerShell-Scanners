
$Multicast = 'HKLM:SOFTWARE\Policies\Microsoft\Windows NT\DNSClient\'

if(Test-Path -Path $Multicast){
  if( (Get-ItemProperty -Path $Multicast -ErrorAction SilentlyContinue -Name 'EnableMulticast') -eq 0){
    $Enabled = $false
    $PSPath = Get-ItemProperty -Path $Multicast -ErrorAction SilentlyContinue  -Name 'EnableMulticast'
    $PSPath = $PSPath.PSPath
  } elseif ((Get-ItemProperty -Path $Multicast -ErrorAction SilentlyContinue  -Name 'EnableMulticast') -eq 1) {
      $Enabled = $true
      $PSPath = Get-ItemProperty -Path $Multicast -ErrorAction SilentlyContinue  -Name 'EnableMulticast'
      $PSPath = $PSPath.PSPath
  } else{
    $Enabled = "EnableMulticast key may not be present in registry. Please investigate further."
  }
} else {
  $Enabled = "Key not found in registry. Please investigate further."
}


[PSCustomObject]@{
    Enabled  = $Enabled
    PSPath = $PSPath.PSPath
} 