#
# Source: http://sharepointjack.com/2017/powershell-script-to-remove-duplicate-old-modules/
# Script1.ps1
#
write-host "this will report all modules with duplicate (older and newer) versions installed"
write-host "be sure to run this as an admin" -foregroundcolor yellow
write-host "(You can update all your Azure RMmodules with update-module Azurerm -force)"

$mods = get-installedmodule

foreach ($Mod in $mods)
{
  write-host "Checking $($mod.name)"
  $latest = get-installedmodule $mod.name
  $specificmods = get-installedmodule $mod.name -allversions
  write-host "$($specificmods.count) versions of this module found [ $($mod.name) ]"
  
 
  foreach ($sm in $specificmods)
  {
     if ($sm.version -eq $latest.version) 
	 { $color = "green"}
	 else
	 { $color = "magenta"}
     write-host " $($sm.name) - $($sm.version) [highest installed is $($latest.version)]" -foregroundcolor $color
	
  }
  write-host "------------------------"
}
write-host "done"