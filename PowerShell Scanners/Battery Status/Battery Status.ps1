$culture = [System.Globalization.CultureInfo]::CurrentCulture.Clone()
$culture.NumberFormat.NumberDecimalSeparator = "."
[System.Threading.Thread]::CurrentThread.CurrentCulture = $culture

$Batteries = (Get-WmiObject -Class "BatteryStatus" -Namespace "ROOT\WMI" -ErrorAction SilentlyContinue)
$AllBatteryData = Get-WmiObject -Class "BatteryStaticData" -Namespace "ROOT\WMI"
$AllCharges = (Get-WmiObject -Class "BatteryFullChargedCapacity" -Namespace "ROOT\WMI").FullChargedCapacity
$BatteryIndex = 0

Foreach ($Battery in $Batteries) {

    $BatteryName = $AllBatteryData.DeviceName.split(" ")[$BatteryIndex]
    $DesignedCapacity = $AllBatteryData.DesignedCapacity[$BatteryIndex]
    $FullCharge = $AllCharges[$BatteryIndex]

    # https://github.com/pdq/PowerShell-Scanners/issues/49
    Try {

        $Health = [Math]::Round($FullCharge / $DesignedCapacity * 100, 2)

    } Catch {

        Write-Warning "DesignedCapacity is 0 or null"
        $Health = $null

    }

    [PSCustomObject]@{
        Name             = $BatteryName
        DesignedCapacity = $DesignedCapacity
        FullCharge       = $FullCharge
        Health           = $Health
    }

    $BatteryIndex ++

}