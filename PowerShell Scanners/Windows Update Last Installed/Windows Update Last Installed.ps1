& '.\Install and Import Module.ps1' -ModuleName "PSWindowsUpdate"

# Store results in a temp variable
$lastResults = Get-WULastResults

#organize results in a PSCustomObject
[PSCustomObject]@{
    LastInstallationDate = [DateTime] $lastResults.LastInstallationSuccessDate
    LastScanSuccessDate  = [DateTime] $lastResults.LastSearchSuccessDate
    IsPendingReboot      = [Bool] (Get-WURebootStatus).RebootRequired
}