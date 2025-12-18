<#
.SYNOPSIS
    Retrieves the Windows Autopilot Hardware Hash for Intune registration.

.DESCRIPTION
    Queries WMI for the MDM_DevDetail_Ext01 class to extract the 4K hardware hash.
    Used for manual enrollment of existing devices into Windows Autopilot.

.OUTPUTS
    PSCustomObject
#>

$WmiPath = "root/cimv2/mdm/dmmap"
$ClassName = "MDM_DevDetail_Ext01"

try {
    # Query the hash from WMI
    $DevDetail = Get-CimInstance -Namespace $WmiPath -ClassName $ClassName -Filter "InstanceID='Ext' AND ParentID='./DevDetail'" -ErrorAction Stop
    
    [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        HardwareHash = $DevDetail.DeviceHardwareData
        SerialNumber = (Get-CimInstance Win32_Bios).SerialNumber
    }
}
catch {
    # If it fails (e.g. older Windows versions), return an error message
    [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        HardwareHash = "Error: WMI Path Not Found (Requires Win 10/11 1703+)"
        SerialNumber = "N/A"
    }
}