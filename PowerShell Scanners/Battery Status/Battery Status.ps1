function Format-Battery($BatteryName = "No Battery Detected", $DesignedCapacity = 0, $FullCharge = 0, $Health = 0) {
    [PSCustomObject]@{
        Name             = $BatteryName
        DesignedCapacity = $DesignedCapacity
        FullCharge       = $FullCharge
        Health           = $Health
    }
}


$Batteries = (Get-WmiObject -Class "BatteryStatus" -Namespace "ROOT\WMI" -ErrorAction SilentlyContinue)
$AllBatteryData = Get-WmiObject -Class "BatteryStaticData" -Namespace "ROOT\WMI"
$AllCharges = (Get-WmiObject -Class "BatteryFullChargedCapacity" -Namespace "ROOT\WMI").FullChargedCapacity
$BatteryIndex = 0
foreach ($Battery in $Batteries) {
    $BatteryName = $AllBatteryData.DeviceName.split(" ")[$BatteryIndex]
    $DesignedCapacity = $AllBatteryData.DesignedCapacity[$BatteryIndex]
    $FullCharge = $AllCharges[$BatteryIndex]
    $Health = [math]::Round($FullCharge / $DesignedCapacity * 100, 2)

    Format-Battery $BatteryName $DesignedCapacity $FullCharge $Health
    $BatteryIndex++
}
