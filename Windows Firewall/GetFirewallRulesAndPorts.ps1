# https://itluke.online/2018/11/27/how-to-display-firewall-rule-ports-with-powershell/

Get-NetFirewallRule -DisplayGroup 'Remote Desktop' |
Format-Table -Property Name,
DisplayName,
DisplayGroup,
@{Name='Protocol';Expression={($PSItem | Get-NetFirewallPortFilter).Protocol}},
@{Name='LocalPort';Expression={($PSItem | Get-NetFirewallPortFilter).LocalPort}},
@{Name='RemotePort';Expression={($PSItem | Get-NetFirewallPortFilter).RemotePort}},
@{Name='RemoteAddress';Expression={($PSItem | Get-NetFirewallAddressFilter).RemoteAddress}},
Enabled,
Profile,
Direction,
Action