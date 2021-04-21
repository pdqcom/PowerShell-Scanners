param (
    [Switch]$MacAddress
)

$Params = @{
    'Namespace' = 'root/CIMV2/mdm/dmmap'
    'ClassName' = 'MDM_DevDetail_Ext01'
    'Filter'    = "InstanceID='Ext' AND ParentID='./DevDetail'"
}
$Data = Get-CimInstance @Params

$Result = [Ordered]@{
    'Hardware Hash' = $Data.DeviceHardwareData
}

if ( $MacAddress ) {

    $Result.'WLAN MAC Address' = $Data.WLANMACAddress

}

[PSCustomObject]$Result