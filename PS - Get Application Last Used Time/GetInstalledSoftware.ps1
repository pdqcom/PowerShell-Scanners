$computer = $env:computer
Get-WmiObject -Namespace ROOT\CIMV2 -Class Win32_SoftwareFeature | where Caption contains 'Outlook'