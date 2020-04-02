# Install the PSWindowsUpdate module if it is not already installed
Try {

    $null = Get-InstalledModule PSWindowsUpdate -ErrorAction Stop

} Catch {

    if ( -not ( Get-PackageProvider -ListAvailable | Where-Object Name -eq "Nuget" ) ) {

        $null = Install-PackageProvider Nuget -Force

    }

    $null = Install-Module PSWindowsUpdate -Force

}

# Load the module
$null = Import-Module PSWindowsUpdate -Force



# Run the actual cmdlet, finally :)
Get-WUHistory