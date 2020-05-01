# This is required for Verbose to work correctly.
# If you don't want the Verbose message, remove "-Verbose" from the Parameters field.
[CmdletBinding()]
param (
    [parameter()]
    [switch]
    $Enabled
)

if([version](Get-WmiObject win32_operatingsystem).Version -lt 6.2.0){ 
    throw "This scanner only available on Windows Server 2012 and higher" 
}

switch($Enabled){

    $true { Get-NetFirewallRule -Enabled True | Select-Object Name,DisplayName,Description,Profile,Direction,Action }
    $false{ Get-NetFirewallRule | Select-Object Name,DisplayName,Description,Enabled,Profile,Direction,Action }
}

