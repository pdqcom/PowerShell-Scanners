#https://community.spiceworks.com/topic/2181149-dell-command-suite-with-powershell
$ComputerName = $env:computername #Change SomeHost to the name of the Dell Computer whose BIOS you want to access remotely.kjy7\

$LoadDellBIOSProviderAndGetBIOSSettingsScriptBlock = {

If (Get-Module -ListAvailable -Name DellBIOSProvider)

{

$GetModuleResult = "Already-Installed";

Import-Module DellBIOSProvider -RequiredVersion 2.3.1  -Force -ErrorVariable $ImportModuleResult;

IF($ImportModuleResult -eq $null){$ImportModuleResult = 0};

$InstallModuleResult = "N/A"

}

Else

{

$GetModuleResult = "Not-Installed:Installing";

Install-Module -Name DellBIOSProvider -RequiredVersion 2.3.1 -Force -ErrorVariable $InstallModuleResult;

IF ($InstallModuleResult -eq $null){$InstallModuleResult = 0};

Import-Module DellBIOSProvider -Force -ErrorVariable $ImportModuleResult;

IF ($ImportModuleResult -eq $null){$ImportModuleResult = 0};

}

$DellBiosCommands = get-command -module DellBIOSProvider;

function Get-DellBiosSettings {

<#

.Synopsis

retrieves all BIOS settings applicable to the system

.Description

This CmdLet retrieves the BIOS settings that are applicable to the system.

.Example

Get-DellBiosSettings

#>

BEGIN { }

PROCESS {

$DellBIOS = get-childitem -path DellSmbios:\ | Select-Object category |

ForEach-Object {

get-childitem -path @("DellSmbios:\" + $_.Category)

}

$DellBIOS

}

END{ }

} #end function Get-DellBiosSettings

$DellBIOSSettings = Get-DellBiosSettings;

return $GetModuleResult, $InstallModuleResult, $ImportModuleResult, $DellBiosCommands, $DellBIOSSettings

} #end $LoadDellBIOSProviderScriptBlock

$DellBiosDump = Invoke-Command -ComputerName $ComputerName -ScriptBlock $LoadDellBIOSProviderAndGetBIOSSettingsScriptBlock

write-host "DellBIOSProvider was:" $DellBiosDump[0] -BackgroundColor Blue

write-host "InstallModlue Error:" $DellBiosDump[1] -BackgroundColor Blue

write-host "ImportModlue Error:" $DellBiosDump[2] -BackgroundColor Blue

write-host "Dell BIOS Provider Commands Available" -BackgroundColor Blue; $DellBiosDump[3]

write-host "Dell BIOS Settings" -BackgroundColor Blue; $DellBiosDump[4]

$DellBiosDump[4] | export-csv -LiteralPath c:\temp\DellBiosDump.csv -NoTypeInformation