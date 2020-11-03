if (Get-CimInstance -ClassName Win32_ComputerSystem -Filter:"Manufacturer LIKE '%Dell%'") {
    $null = Install-Module DellBIOSProvider -Force
    $null = Import-Module DellBIOSProvider -Force
    Get-ChildItem DellSmbios:\ | ForEach-Object {
        $Category = $_.Category
        Get-ChildItem DellSmbios:\"$Category" | ForEach-Object {
            [PSCustomObject]@{
                Category     = $Category
                Attribute    = $_.Attribute
                Description  = $_.Description
                CurrentValue = $_.CurrentValue
            }
        } 
    }
} 