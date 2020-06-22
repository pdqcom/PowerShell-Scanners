if ( -Not ( Get-Command Get-SmbConnection ) ) {

    throw "Get-SmbConnection is only available on Windows 8 or later."

}

$Properties = @(
    "ServerName"
    "ShareName"
    "Credential"
    "UserName"
    "Encrypted"
    "Signed"
    @{ Name = "OpenHandles"; Expression = { $_.NumOpens } } # https://docs.microsoft.com/en-us/previous-versions/windows/desktop/smb/msft-smbconnection#properties
    "Dialect"
    "Redirected"
    "ContinuouslyAvailable"
)

Get-SmbConnection | Select-Object $Properties