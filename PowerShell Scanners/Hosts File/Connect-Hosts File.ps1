# PowerShell 7 compatible version for PDQ Connect.
# The Inventory version uses ConvertFrom-String which is not available in PowerShell 7+.
# This version parses the same data using basic string splitting.

[CmdletBinding()]
param (
    [Switch]$ShowDisabled
)

$FileContents = (Get-Content "$env:SystemRoot\System32\drivers\etc\hosts").Trim() | Where-Object { $_ }

$Count = 0
$hostsinfile = $null

Foreach ( $Line in $FileContents ) {

    $OriginalLine = $Line
    $Enabled = $true
    $Count ++

    if ( $Line.StartsWith('#') ) {

        if ( $ShowDisabled ) {

            $Enabled = $false
            $Line = $Line.TrimStart('# ')

        } else {

            Write-Verbose "Line #$Count is a comment and ShowDisabled is not active."
            Continue

        }

    }

    # Strip trailing inline comment.
    $Line, $Comments = ($Line -split '#', 2).Trim()

    if ( -not $Line ) {

        Write-Verbose "Line #$Count is an empty comment."
        Continue

    }

    # Split on whitespace into tokens.
    $Tokens = $Line -split '\s+' | Where-Object { $_ }

    if ( $Tokens.Count -lt 2 ) {

        if ( $Enabled ) {
            Write-Error "Malformed line: '$OriginalLine'"
        }
        Write-Verbose "Line #$Count could not be split."
        Continue

    }

    $IPAddress = $Tokens[0]

    # Validate IP address.
    try {
        $null = [ipaddress]$IPAddress
    } catch {
        Write-Verbose "Line #$Count does not start with an IP address."
        Continue
    }

    # Output one object per hostname on the line.
    foreach ( $HostName in $Tokens[1..($Tokens.Count - 1)] ) {

        $hostsinfile = [PSCustomObject]@{
            'HostName'  = $HostName
            'IPAddress' = $IPAddress
            'Enabled'   = $Enabled
            'Comments'  = $Comments
        }
        $hostsinfile

    }

}

if ( $null -eq $hostsinfile ) {
    [PSCustomObject]@{
        'HostName'  = $null
        'IPAddress' = $null
        'Enabled'   = $false
        'Comments'  = $null
    }
}
