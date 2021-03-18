# Based on https://help.pdq.com/hc/en-us/community/posts/360050799132-Firefox-extension-inventory
[CmdletBinding()]
param (
    [Switch]$EnablePermissions,
    [Switch]$EnableDefaultExtensions
)

Foreach ( $User in (Get-ChildItem -Directory -Path "$env:SystemDrive\Users") ) {

    # Get Profiles folder
    $ProfilesDir = $User.FullName + "\AppData\Roaming\Mozilla\Firefox\Profiles"

    # Skip this round of the loop if no Profiles folder is present
    if ( -Not (Test-Path $ProfilesDir) ) {

        Continue

    }

    Foreach ( $ExtensionFile in (Get-ChildItem -Path $ProfilesDir -File -Filter "extensions.json" -Recurse)) {

        $ExtensionDir = $ExtensionFile.DirectoryName
        
        # Get Firefox version - yes it is in the loop. Had to determine profile location.
        $FirefoxVersion = $null
        Foreach ( $Line in (Get-Content "$ExtensionDir\compatibility.ini" -ErrorAction SilentlyContinue) ) {

            if ( $Line.StartsWith("LastVersion") ) {

                # Split on = and _, then grab the first element
                $FirefoxVersion = ($Line -split "[=_]")[1]

            }

        }
        
        # Read extensions JSON file
        $ExtensionJson = (Get-Content $ExtensionFile.FullName | ConvertFrom-Json).Addons

        Foreach ( $Extension in $ExtensionJson ) {
                
            $Location = $Extension.Location

            # Skip default extensions
            if ( -Not $EnableDefaultExtensions ) {

                if ( "app-builtin", "app-system-defaults" -contains $Location ) {

                    Continue

                }

            }
            
            # Convert InstallDate
            $InstallTime = [Double]$Extension.InstallDate
            # Divide by 1,000 because we are going to add seconds on to the base date
            $InstallTime = $InstallTime / 1000
            $UtcTime = Get-Date -Date "1970-01-01 00:00:00"
            $UtcTime = $UtcTime.AddSeconds($InstallTime)
            $LocalTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($UtcTime, (Get-TimeZone))
        
            $Output = [Ordered]@{
                User         = [String]  $User
                Name         = [String]  $Extension.DefaultLocale.Name
                Version      = [String]  $Extension.Version
                Enabled      = [Bool]    $Extension.Active
                InstallDate  = [DateTime]$LocalTime
                Description  = [String]  $Extension.DefaultLocale.Description
                ID           = [String]  $Extension.Id
                FirefoxVer   = [String]  $FirefoxVersion
                Visible      = [Bool]    $Extension.Visible
                AppDisabled  = [Bool]    $Extension.AppDisabled
                UserDisabled = [Bool]    $Extension.UserDisabled
                Hidden       = [Bool]    $Extension.Hidden
                Location     = [String]  $Location
                SourceUri    = [String]  $Extension.SourceUri
            }

            if ( $EnablePermissions ) {

                # Convert Permissions array into a multi-line string
                # This multi-line string is kind of ugly in Inventory, so it's disabled by default
                $Output.Permissions = [String]($Extension.UserPermissions.Permissions -Join "`n")

            }

            [PSCustomObject]$Output
        
        }

    }

}