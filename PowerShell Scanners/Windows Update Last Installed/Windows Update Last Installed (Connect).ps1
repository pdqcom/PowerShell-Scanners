# Self-contained version for PDQ Connect. Uses the built-in Windows Update COM API,
# so there is no module to install.
$AutoUpdateResults = (New-Object -ComObject 'Microsoft.Update.AutoUpdate').Results

# SystemInfo is denied to non-elevated users, so fall back to the registry flags that Windows Update and CBS set.
try {

    $RebootRequired = [Bool](New-Object -ComObject 'Microsoft.Update.SystemInfo' -ErrorAction Stop).RebootRequired

} catch {

    $RebootRequired = [Bool](
        (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') -or
        (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending')
    )

}

[PSCustomObject]@{
    LastInstallationDate = [DateTime]$AutoUpdateResults.LastInstallationSuccessDate
    LastScanSuccessDate  = [DateTime]$AutoUpdateResults.LastSearchSuccessDate
    IsPendingReboot      = $RebootRequired
}
