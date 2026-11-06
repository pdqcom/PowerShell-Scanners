# Inline module installer for PDQ Connect (no relative path support)
function Install-AndImportModule {
    param (
        [Parameter(Mandatory = $true)]
        [String]$ModuleName
    )
    try {
        $null = Get-InstalledModule $ModuleName -ErrorAction Stop
    } catch {
        if (-not (Get-PackageProvider -ListAvailable | Where-Object Name -eq "Nuget")) {
            $null = Install-PackageProvider "Nuget" -Force
        }
        $null = Install-Module $ModuleName -Force
    }
    $null = Import-Module $ModuleName -Force
}

if (Get-CimInstance -ClassName Win32_ComputerSystem -Filter "Manufacturer LIKE '%Dell%'") {
    $ModuleName = "DellBIOSProvider"
    if (-not [Environment]::Is64BitOperatingSystem) {
        $ModuleName += "X86"
    }
    Install-AndImportModule -ModuleName $ModuleName
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
