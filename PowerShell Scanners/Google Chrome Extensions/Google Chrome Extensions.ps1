# Based on https://help.pdq.com/hc/en-us/community/posts/360050592031-chrome-extension-inventory
[CmdletBinding()]
param (
    [Switch]$EnablePermissions
)

Foreach ( $User in (Get-ChildItem -Directory -Path "$env:SystemDrive\Users") ) {

    # Get profile folder
    $ChromeDir = $User.FullName + "\AppData\Local\Google\Chrome\User Data"
    $PreferencesFile = ""

    if ( Test-Path "$ChromeDir\Default\Preferences" ) {

        $PreferencesFile = "$ChromeDir\Default\Preferences"
        Write-Verbose "Found --- $PreferencesFile"

    }

    if ( Test-Path "$ChromeDir\Profile 1\Preferences" ) {

        $PreferencesFile = "$ChromeDir\Profile 1\Preferences"
        Write-Verbose "Found --- $PreferencesFile"

    }



    # Skip this round of the loop if no file was found
    if ( -Not $PreferencesFile ) {

        Continue

    }

    # Read Preferences JSON file
    # This .NET method is necessary because ConvertFrom-Json can't handle duplicate entries with different cases.
    # https://github.com/pdq/PowerShell-Scanners/issues/23
    Add-Type -AssemblyName System.Web.Extensions
    $PreferencesText = Get-Content $PreferencesFile
    $JsonParser = New-Object -TypeName System.Web.Script.Serialization.JavaScriptSerializer
    $PreferencesJson = $JsonParser.DeserializeObject($PreferencesText)

    Foreach ( $Extension in $PreferencesJson.extensions.settings.GetEnumerator() ) {

        $ID = $Extension.Key
        $Extension = $Extension.Value
        $Name = $Extension.manifest.name

        # Ignore blank names
        if ( -Not $Name ) {

            Write-Verbose "Blank name for ID: $ID"
            Continue

        }

        # Convert Install_Time
        $InstallTime = [Double]$Extension.install_time
        # Divide by 1,000,000 because we are going to add seconds on to the base date
        $InstallTime = ($InstallTime - 11644473600000000) / 1000000
        $UtcTime = Get-Date -Date "1970-01-01 00:00:00"
        $UtcTime = $UtcTime.AddSeconds($InstallTime)
        $LocalTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($UtcTime, (Get-TimeZone))

        $Output = [Ordered]@{
            Name           = [String]  $Name
            Version        = [String]  $Extension.manifest.version
            Enabled        = [Bool]    $Extension.state
            Description    = [String]  $Extension.manifest.description
            DefaultInstall = [Bool]    $Extension.was_installed_by_default
            OemInstall     = [Bool]    $Extension.was_installed_by_oem
            ID             = [String]  $ID
            InstallDate    = [DateTime]$LocalTime
            User           = [String]  $User
            ChromeVer      = [String]  $PreferencesJson.extensions.last_chrome_version
        }

        if ( $EnablePermissions ) {

            # Convert Permissions array into a multi-line string
            # This multi-line string is kind of ugly in Inventory, so it's disabled by default
            $Output.Permissions = [String]($Extension.manifest.permissions -Join "`n")

        }

        [PSCustomObject]$Output
    
    }

}