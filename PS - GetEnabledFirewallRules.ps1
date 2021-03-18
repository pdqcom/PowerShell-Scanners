# https://stackoverflow.com/questions/6597951/how-can-you-check-for-existing-firewall-rules-using-powershell

Function Get-EnabledRules
{
    Param($profile)
    $rules = (New-Object -comObject HNetCfg.FwPolicy2).rules
    $rules = $rules | where-object {$_.Enabled -eq $true}
    $rules = $rules | where-object {$_.Profiles -bAND $profile}
    $rules
}

$networkListManager = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]"{DCB00C01-570F-4A9B-8D69-199FDBA5723B}"))
 $connections = $networkListManager.GetNetworkConnections()
[int[] ] $connTypes = @()
$connTypes = ($connections | % {$_.GetNetwork().GetCategory()})
#$connTypes += 1
Write-Host $connTypes

$connTypes | ForEach-Object {Get-EnabledRules -profile $_ | sort localports,Protocol | format-table -wrap -autosize -property Name, @{Label="Action"; expression={$_.action}}, @{Label="Protocol"; expression={$_.protocol}}, localPorts,applicationname}