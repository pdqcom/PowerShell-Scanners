[cmdletBinding()]
param(
    [parameter()]
    [switch]
    $Enabled
)

process{
    
    if([version](Get-WmiObject win32_operatingsystem).Version -lt 6.3.0){
        throw "This scanner only available on Server 2012/Windows8 or higher"
    }
    
    switch($Enabled){
        $true { Get-NetFirewallRule -Enabled True| Select-Object Name,DisplayName,Description,Profile,Direction,Action }
        $false{ Get-NetFirewallRule | Select-Object Name,DisplayName,Description,Enabled,Profile,Direction,Action }
    }

}