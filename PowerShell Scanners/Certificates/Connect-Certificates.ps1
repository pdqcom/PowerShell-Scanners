# Trimmed version for PDQ Connect. Uses a fixed set of properties rather than exposing
# -Property, which can produce very large output when set to '*'.
# Defaults to LocalMachine only, since CurrentUser stores are less relevant in a Connect context.

[CmdletBinding()]
param (
    [ValidateSet('CurrentUser', 'LocalMachine')]
    [String[]]$StoreLocation = @('LocalMachine'),

    [String[]]$StoreName
)

$CertType = [System.Security.Cryptography.X509Certificates.X509Certificate2]

$Properties = @(
    'FriendlyName'
    'NotBefore'
    'NotAfter'
    'Thumbprint'
    'SerialNumber'
    @{ Label = 'Store'; Expression = { ($_.PSParentPath -split ':')[-1] } }
)

foreach ( $StoreLocationIterator in $StoreLocation ) {

    if ( $StoreName ) {

        foreach ( $StoreNameIterator in $StoreName ) {

            $Param = @{
                'Path'        = "Cert:\$StoreLocationIterator\$StoreNameIterator"
                'ErrorAction' = 'SilentlyContinue'
            }
            Get-ChildItem @Param | Where-Object { $_ -is $CertType } | Select-Object $Properties

        }

    } else {

        $Param = @{
            'Path'        = "Cert:\$StoreLocationIterator"
            'ErrorAction' = 'SilentlyContinue'
            'Recurse'     = $true
        }
        Get-ChildItem @Param | Where-Object { $_ -is $CertType } | Select-Object $Properties

    }

}
