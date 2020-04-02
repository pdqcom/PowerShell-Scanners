# This is required for Verbose to work correctly.
# If you don't want the Verbose message, remove "-Verbose" from the Parameters field.
[CmdletBinding()]
param ()

# On most OSes, HKEY_USERS only contains users that are logged on.
# There are ways to load the other profiles, but it can be problematic.
$Drives = Get-ItemProperty "Registry::HKEY_USERS\*\Network\*"

# See if any drives were found
if ( $Drives ) {

    ForEach ( $Drive in $Drives ) {

        # PSParentPath looks like this: Microsoft.PowerShell.Core\Registry::HKEY_USERS\S-1-5-21-##########-##########-##########-####\Network
        $SID = ($Drive.PSParentPath -split '\\')[2]

        [PSCustomObject]@{
            # Use .NET to look up the username from the SID
            Username            = ([System.Security.Principal.SecurityIdentifier]"$SID").Translate([System.Security.Principal.NTAccount])
            DriveLetter         = $Drive.PSChildName
            RemotePath          = $Drive.RemotePath

            # The username specified when you use "Connect using different credentials".
            # For some reason, this is frequently "0" when you don't use this option. I remove the "0" to keep the results consistent.
            ConnectWithUsername = $Drive.UserName -replace '^0$', $null
            SID                 = $SID
        }

    }

} else {

    Write-Verbose "No mapped drives were found"

}