[cmdletBinding()]
param(
    [parameter()]
    [switch]
    $Enabled
)

process{
    
    if([version](Get-CimInstance win32_operatingsystem).Version -lt 6.3.0){
        throw "This scanner is only available on Server 2012/Windows 8 or higher"
    }
    
    switch($Enabled){
        $true { Get-NetFirewallRule -Enabled True| Select-Object Name,DisplayName,Description,Profile,Direction,Action }
        $false { Get-NetFirewallRule | Select-Object Name,DisplayName,Description,Enabled,Profile,Direction,Action }
    }

}