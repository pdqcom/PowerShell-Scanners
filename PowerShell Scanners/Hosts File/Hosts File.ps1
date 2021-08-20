[CmdletBinding()]
param (
    [Switch]$ShowDisabled
)

# Read the hosts file, remove whitespace from each end, and discard empty lines.
$FileContents = (Get-Content "$env:SystemRoot\System32\drivers\etc\hosts").Trim() | Where-Object { $_ }

$Count = 0
Foreach ( $Line in $FileContents ) {

    $OriginalLine = $Line
    $Enabled = $true
    $Count ++
    
    # Determine if the entire line is a comment (or disabled).
    if ( $Line.StartsWith('#') ) {

        if ( $ShowDisabled ) {

            $Enabled = $false
            
            # Remove the leading #, and any whitespace.
            $Line = $Line.TrimStart('# ')

        } else {
            
            Write-Verbose "Line #$Count is a comment and ShowDisabled is not active."
            Continue

        }

    }

    # Check for a comment at the end of the line.
    $Line, $Comments = ($Line -split '#', 2).Trim()

    # Sometimes lines are just an empty comment.
    if ( -not $Line ) {
        
        Write-Verbose "Line #$Count is an empty comment."
        Continue

    }

    # Split the line (a string) into an object.
    $ParsedLine = $Line | ConvertFrom-String
    
    # ConvertFrom-String can return $null if the input can't be split, such as an empty string or a single word.
    if ( -not $ParsedLine ) {

        if ( $Enabled ) {
            
            # You should only see this if the line contains an IP address without any hostnames.
            Write-Error "Malformed line: '$OriginalLine'"

        }
        
        Write-Verbose "Line #$Count could not be split."
        Continue

    }

    # Determine if the first property is an IP address.
    Try {

        $null = [ipaddress]$ParsedLine.P1

    } Catch {

        Write-Verbose "Line #$Count does not start with an IP address."
        Continue
        
    }

    # Determine the number of properties.
    $PropertyCount = ([Array]$ParsedLine.PsObject.Properties.Name).Count

    # Output an object for each hostname.
    Foreach ( $PropertyNumber in 2..$PropertyCount ) {

        [PSCustomObject]@{
            'HostName'  = $ParsedLine."P$PropertyNumber"
            'IPAddress' = $ParsedLine.P1
            'Enabled'   = $Enabled
            'Comments'  = $Comments
        }

    }

}