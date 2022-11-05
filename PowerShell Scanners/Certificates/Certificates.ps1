[CmdletBinding()]
param (
    [ValidateSet('Archived', 'DnsNameList', 'EnhancedKeyUsageList', 'EnrollmentPolicyEndPoint',
        'EnrollmentServerEndPoint', 'Extensions', 'FriendlyName', 'Handle', 'HasPrivateKey', 'Issuer', 'IssuerName',
        'NotAfter', 'NotBefore', 'PolicyId', 'PrivateKey', 'PSChildName', 'PSDrive', 'PSIsContainer', 'PSParentPath',
        'PSPath', 'PSProvider', 'PublicKey', 'RawData', 'SendAsTrustedIssuer', 'SerialNumber', 'SignatureAlgorithm',
        'Subject', 'SubjectName', 'Thumbprint', 'Version', '*')]
    [String[]]$Property = [String[]]('FriendlyName', 'NotBefore', 'NotAfter', 'Thumbprint', 'SerialNumber', 'PSParentPath'),

    [ValidateSet('CurrentUser', 'LocalMachine')]
    [String[]]$StoreLocation = @('CurrentUser', 'LocalMachine'),

    [String[]]$StoreName
)

$CertType = [System.Security.Cryptography.X509Certificates.X509Certificate2]

# Replace PSPath and PSParentPath with expressions that will trim their output.
$Properties = @()
foreach ( $PropertyIterator in $Property ) {

    if ( $PropertyIterator -eq 'PSPath' ) {

        $Properties += @{Label = 'PSPath'; Expression = { ($_.PSPath -split ':')[-1] } }

    } elseif ($PropertyIterator -eq 'PSParentPath') {
        
        $Properties += @{Label = 'PSParentPath'; Expression = { ($_.PSParentPath -split ':')[-1] } }
    
    } else {

        $Properties += $PropertyIterator

    }

}

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