# Based on https://help.pdq.com/hc/en-us/community/posts/360050592031-chrome-extension-inventory
[CmdletBinding()]
param (
    [Switch]$EnablePermissions
)

function Convert-UtcToLocal {
    param(
        [parameter(Mandatory = $true)]
        [String]$UtcTime
    )

    $CurrentTimeZone = (Get-CimInstance Win32_TimeZone 4>null).StandardName
    $TZ = [System.TimeZoneInfo]::FindSystemTimeZoneById($CurrentTimeZone)
    
    [System.TimeZoneInfo]::ConvertTimeFromUtc($UtcTime, $TZ)
}



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
    $PreferencesJson = Get-Content $PreferencesFile | ConvertFrom-Json

    # https://andrewpla.dev/Iterate-Over-Object-Properties/
    Foreach ( $Extension in (($PreferencesJson.Extensions.Settings).PSObject.Members | Where-Object MemberType -eq 'NoteProperty') ) {

        $ID = $Extension.Name
        $Extension = $Extension.Value
        $Name = $Extension.Manifest.Name

        # Ignore blank names
        if ( -Not $Name ) {

            Write-Verbose "Blank name for ID: $ID"
            Continue

        }
            
        # Convert Install_Time
        $InstallTime = [Double]$Extension.Install_Time
        # Divide by 1,000,000 because we are going to add seconds on to the base date
        $InstallTime = ($InstallTime - 11644473600000000) / 1000000
        $UtcTime = Get-Date -Date "1970-01-01 00:00:00"
        $UtcTime = $UtcTime.AddSeconds($InstallTime)
        $LocalTime = Convert-UtcToLocal($UtcTime)
    
        $Output = [PSCustomObject]@{
            Name           = [String]  $Name
            Version        = [String]  $Extension.Manifest.Version
            Enabled        = [Bool]    $Extension.State
            Description    = [String]  $Extension.Manifest.Description
            DefaultInstall = [Bool]    $Extension.Was_Installed_By_Default
            OemInstall     = [Bool]    $Extension.Was_Installed_By_OEM
            ID             = [String]  $ID
            InstallDate    = [DateTime]$LocalTime
            User           = [String]  $User
            ChromeVer      = [String]  $PreferencesJson.Extensions.Last_Chrome_Version
        }

        if ( $EnablePermissions ) {

            # Convert Permissions array into a multi-line string
            # This multi-line string is kind of ugly in Inventory, so it's disabled by default
            $Output.Permissions = [String]($Extension.Manifest.Permissions -Join "`n")

        }

        $Output
    
    }

}