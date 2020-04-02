& '.\Install and Import Module.ps1' -ModuleName "PSWindowsUpdate"

[PSCustomObject]@{
    LastInstallationDate = [DateTime](Get-WULastInstallationDate)
    LastScanSuccessDate  = [DateTime](Get-WULastScanSuccessDate)
    IsPendingReboot      = [Bool](Get-WUIsPendingReboot)
}