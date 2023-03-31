if (Get-CimInstance -ClassName Win32_ComputerSystem -Filter "Manufacturer LIKE '%Dell%'") {
    $ModuleName = "DellBIOSProvider"
    if (-not [Environment]::Is64BitOperatingSystem) {
        $ModuleName += "X86"
    }
    & '.\Install and Import Module.ps1' -ModuleName $ModuleName
    Get-ChildItem DellSmbios:\ | ForEach-Object {
        $Category = $_.Category
        Get-ChildItem DellSmbios:\"$Category" -ErrorAction SilentlyContinue | ForEach-Object {
            [PSCustomObject]@{
                Category     = $Category
                Attribute    = $_.Attribute
                Description  = $_.Description
                CurrentValue = $_.CurrentValue
            }
        }
    }
}
