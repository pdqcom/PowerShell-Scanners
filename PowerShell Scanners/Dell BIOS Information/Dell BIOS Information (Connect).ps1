# Self-contained version for PDQ Connect.
# The device needs internet access to the PowerShell Gallery the first time this runs.
if ( -not (Get-CimInstance -ClassName Win32_ComputerSystem -Filter "Manufacturer LIKE '%Dell%'") ) {

    # Connect expects an object, so emit one with null values instead of nothing.
    [PSCustomObject]@{
        Category     = $null
        Attribute    = $null
        Description  = $null
        CurrentValue = $null
    }
    return

}

$ModuleName = 'DellBIOSProvider'
if ( -not [Environment]::Is64BitOperatingSystem ) {

    $ModuleName += 'X86'

}

# Windows PowerShell 5.1 does not use TLS 1.2 by default, which the PowerShell Gallery requires.
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Install the module if it is not already installed, then load it.
if ( -not (Get-Module -ListAvailable -Name $ModuleName) ) {

    if ( -not (Get-PackageProvider -ListAvailable | Where-Object Name -eq 'NuGet') ) {

        $null = Install-PackageProvider 'NuGet' -Force

    }

    $null = Install-Module $ModuleName -Force

}

$null = Import-Module $ModuleName -Force

Get-ChildItem DellSmbios:\ | ForEach-Object {

    $Category = $_.Category
    Get-ChildItem "DellSmbios:\$Category" -ErrorAction SilentlyContinue | ForEach-Object {

        [PSCustomObject]@{
            Category     = $Category
            Attribute    = $_.Attribute
            Description  = $_.Description
            CurrentValue = $_.CurrentValue
        }

    }

}
