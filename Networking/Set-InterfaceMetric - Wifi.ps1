#Get-NetIPInterface | Where-Object {$_.InterfaceAlias -match "Ethernet*|Wi-Fi" -and $_.ConnectionState -eq 'Connected'} | Set-NetIPInterface -InterfaceMetric 15
Get-NetIPInterface | Where-Object {$_.InterfaceAlias -match "Wi-Fi" -and $_.ConnectionState -eq 'Connected'} | Set-NetIPInterface -InterfaceMetric 15 -verbose
Get-NetIPInterface | Where-Object {$_.InterfaceAlias -match "Wi-Fi" -and $_.ConnectionState -eq 'Connected'} 
# https://cloudrun.co.uk/windows10/set-network-interface-priority-in-windows-10-using-set-netipinterface/
# https://docs.microsoft.com/en-us/powershell/module/nettcpip/set-netipinterface?view=win10-ps
# https://billysoftacademy.com/how-to-set-the-priority-order-of-network-adapters-on-windows-10/