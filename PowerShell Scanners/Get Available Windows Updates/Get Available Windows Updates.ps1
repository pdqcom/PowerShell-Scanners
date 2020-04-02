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



# The PowerShell Scanner currently does not understand the Collection object this cmdlet emits,
# so we have to assign it to a variable to get PowerShell to unwrap it for us.
$GWU = Get-WindowsUpdate
$GWU