param (
    # PDQ Inventory reads this from Scanner.log; in Connect use a parameter with a sensible default.
    [Int32]$Limit = 200
)

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

Install-AndImportModule -ModuleName "PSWindowsUpdate"

# -Last limits the number of results. This is necessary in Windows 10 2004 and later.
# https://github.com/pdq/PowerShell-Scanners/issues/74
Get-WUHistory -Last $Limit
