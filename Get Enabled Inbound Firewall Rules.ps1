#"C:\Program Files\PowerShell\7\pwsh.exe"
Get-NetFirewallRule | Where { $_.Enabled –eq ‘True’ –and $_.Direction –eq ‘Inbound’}