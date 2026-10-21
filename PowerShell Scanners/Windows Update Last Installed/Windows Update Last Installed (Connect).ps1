# Self-contained version for PDQ Connect. Uses the built-in Windows Update COM API,
# so there is no module to install.
$AutoUpdateResults = (New-Object -ComObject 'Microsoft.Update.AutoUpdate').Results
$RebootRequired = (New-Object -ComObject 'Microsoft.Update.SystemInfo').RebootRequired

[PSCustomObject]@{
    LastInstallationDate = [DateTime]$AutoUpdateResults.LastInstallationSuccessDate
    LastScanSuccessDate  = [DateTime]$AutoUpdateResults.LastSearchSuccessDate
    IsPendingReboot      = [Bool]$RebootRequired
}
