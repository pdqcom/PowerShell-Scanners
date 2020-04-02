# Install the PSWindowsUpdate module if it is not already installed, then load it.
Try {

    $null = Get-InstalledModule PSWindowsUpdate

} Catch {

    if ( -not ( Get-PackageProvider -ListAvailable | Where-Object Name -eq "Nuget" ) ) {

        $null = Install-PackageProvider Nuget -Force

    }

    $null = Install-Module PSWindowsUpdate -Force

}

$null = Import-Module PSWindowsUpdate -Force



[PSCustomObject]@{
    LastInstallationDate = [DateTime](Get-WULastInstallationDate)
    LastScanSuccessDate  = [DateTime](Get-WULastScanSuccessDate)
    IsPendingReboot      = [Bool](Get-WUIsPendingReboot)
}