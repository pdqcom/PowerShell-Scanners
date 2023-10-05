# This script requires that Audit Logon events are enabled in Group Policy and those events are kept for the amount of history preferred

[CmdletBinding()]
param (
    [Switch]$Lowercase
)

$UserArray = New-Object System.Collections.ArrayList

# Query all logon events with id 4624 
Get-EventLog -LogName "Security" -newest 200 -InstanceId 4624 -ErrorAction "SilentlyContinue" | ForEach-Object {

    $EventMessage = $_
    $AccountName = $EventMessage.ReplacementStrings[5]
    $LogonType = $EventMessage.ReplacementStrings[8]

    if ( $Lowercase ) {

        # Make all usernames lowercase so they group properly in Inventory
        $AccountName = $AccountName.ToLower()

    }

    # Look for events that contain local or remote logon events, while ignoring Windows service accounts
    if ( ( $LogonType -in "2", "10", "11" ) -and ( $AccountName -notmatch "^(DWM|UMFD)-\d" ) ) {
    
        # Skip duplicate names
        if ( $UserArray -notcontains $AccountName ) {

            $null = $UserArray.Add($AccountName)
            
            # Translate the Logon Type
            if ( $LogonType -eq "2" ) {

                $LogonTypeName = "Local"

            } elseif ( $LogonType -eq "10" ) {

                $LogonTypeName = "Remote"

            } elseif ( $LogonType -eq "11" ) {
                
                $LogonTypeName = "Cached"
            }

            # Build an object containing the Username, Logon Type, and Last Logon time
            [PSCustomObject]@{
                Username  = $AccountName
                LogonType = $LogonTypeName
                LastLogon = [DateTime]$EventMessage.TimeGenerated.ToString("yyyy-MM-dd HH:mm:ss")
            }  

        }

    }

}