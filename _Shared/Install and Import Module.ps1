[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $ModuleName
)

# Install the module if it is not already installed, then load it.
Try {

    $null = Get-InstalledModule $ModuleName -ErrorAction Stop

} Catch {

    if ( -not ( Get-PackageProvider -ListAvailable | Where-Object Name -eq "Nuget" ) ) {

        $null = Install-PackageProvider "Nuget" -Force

    }

    $null = Install-Module $ModuleName -Force

}

$null = Import-Module $ModuleName -Force
