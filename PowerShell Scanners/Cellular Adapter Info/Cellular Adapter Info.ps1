#reference https://community.spiceworks.com/scripts/show/3605-get-cellularadapter
[CmdletBinding()]
param (
    #no Parameters
)

$cellularInfoprops = [ordered]@{}


$adapterInfo = netsh mbn show interfaces
$stateInfo = netsh mbn show read interface=*

# $cellPhoneInfo = New-Object CellularInfo

foreach ($line in $adapterInfo) {
    $line = $line.Split(":").Trim()

    If ($line[0] -like "Name*") { $cellularInfoprops["AdapterName"] = $line[1] }
    If ($line[0] -like "Description*") { $cellularInfoprops["Description"] = $line[1] }
    If ($line[0] -like "Provider*Name*") { $cellularInfoprops["Provider"] = $line[1] }
    If ($line[0] -like "Device*Id*") { $cellularInfoprops["IMEI"] = $line[1] }
    If ($line[0] -like "State*") { $cellularInfoprops["Status"] = $line[1] }
    If ($line[0] -like "Signal*") { $cellularInfoprops["SignalStrength"] = $line[1] }
    If ($line[0] -like "RSSI*/*RSCP*") { $cellularInfoprops["RSSI_RSCP"] = $line[1] }
    If ($line[0] -like "Cellular*class*") { $cellularInfoprops["CellularClass"] = $line[1] }
    If ($line[0] -like "Roaming*") { $cellularInfoprops["Roaming"] = $line[1] }
    If ($line[0] -like "Device*type*") { $cellularInfoprops["DeviceType"] = $line[1] }
    If ($line[0] -like "Firmware*Version*") { $cellularInfoprops["FirmwareVersion"] = $line[1] }
    If ($line[0] -like "Manufacturer*") { $cellularInfoprops["Manufacturer"] = $line[1] }
    If ($line[0] -like "Model*") { $cellularInfoprops["Model"] = $line[1] }
    If ($line[0] -like "Physical*Address*") { $cellularInfoprops["MacAddress"] = $line[1..$($Line.GetUpperBound(0))].ToUpper() -Join ":" }
}

foreach ($line in $stateInfo) {
    $line = $line.Split(":").Trim()

    If ($line[0] -like "State*") { $cellularInfoprops["State"] = $line[1] }
    If ($line[0] -like "Emergency*Mode*") { $cellularInfoprops["EmergencyMode"] = $line[1] }
    If ($line[0] -like "SIM*ICC*ID") { $cellularInfoprops["SIM"] = $line[1] }
    If ($line[0] -like "Number*Of*Telephone*Numbers*") { $cellularInfoprops["NumberOfTelephoneNumbers"] = $line[1] }
    If ($line[0] -like "Telephone*`#*1") { $cellularInfoprops["TelephoneNumber001"] = $line[1].Replace('+', '') }
    If ($line[0] -like "Telephone*`#*2") { $cellularInfoprops["TelephoneNumber001"] = $line[1].Replace('+', '') }
    If ($line[0] -like "Telephone*`#*3") { $cellularInfoprops["TelephoneNumber001"] = $line[1].Replace('+', '') }
    If ($line[0] -like "Telephone*`#*4") { $cellularInfoprops["TelephoneNumber001"] = $line[1].Replace('+', '') }
    If ($line[0] -like "Telephone*`#*5") { $cellularInfoprops["TelephoneNumber001"] = $line[1].Replace('+', '') }

}

[PSCustomObject]$cellularInfoprops