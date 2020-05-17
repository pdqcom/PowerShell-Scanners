function Return-Battery($BatteryName = "No Battery Detected", $DesignedCapacity = 0, $FullCharge = 0, $Health = 0){
    [PSCustomObject]@{
        Name = $BatteryName
        DesignedCapacity = $DesignedCapacity
        FullCharge = $FullCharge
        Health = $Health
    }
}


$Batteries = (Get-WmiObject -Class "BatteryStatus" -Namespace "ROOT\WMI" -ErrorAction SilentlyContinue)
$BatteryIndex = 0
foreach($Battery in $Batteries){
    $BatteryData = Get-WmiObject -Class "BatteryStaticData" -Namespace "ROOT\WMI"
    $BatteryName = $BatteryData.DeviceName.split(" ")[$BatteryIndex]
    $DesignedCapacity = $BatteryData.DesignedCapacity[$BatteryIndex]
    $FullCharge = (Get-WmiObject -Class "BatteryFullChargedCapacity" -Namespace "ROOT\WMI").FullChargedCapacity[$BatteryIndex]
    $Health = [math]::Round($FullCharge/$DesignedCapacity * 100,2)

    Return-Battery $BatteryName $DesignedCapacity $FullCharge $Health
    $BatteryIndex++
}
