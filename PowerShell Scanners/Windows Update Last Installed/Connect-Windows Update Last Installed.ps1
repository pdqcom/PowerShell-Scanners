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

$lastResults = Get-WULastResults

[PSCustomObject]@{
    LastInstallationDate = [DateTime] $lastResults.LastInstallationSuccessDate
    LastScanSuccessDate  = [DateTime] $lastResults.LastSearchSuccessDate
    IsPendingReboot      = [Bool] (Get-WURebootStatus -Silent)
}
