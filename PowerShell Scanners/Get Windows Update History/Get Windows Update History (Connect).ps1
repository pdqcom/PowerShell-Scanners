# Self-contained version for PDQ Connect. Uses the built-in Windows Update COM API,
# so there is no module to install and no Scanner.log to read.
[CmdletBinding()]
param (
    # Maximum number of history entries to return, newest first.
    [UInt32]$Last = 100,

    # Microsoft Store app installs and Defender definition updates are logged many times a day
    # and would otherwise push the OS updates out of the -Last window. They are excluded unless requested.
    [Switch]$IncludeStoreApps,
    [Switch]$IncludeDefinitionUpdates
)

$Searcher = (New-Object -ComObject 'Microsoft.Update.Session').CreateUpdateSearcher()
$Total = $Searcher.GetTotalHistoryCount()

$Operations = @{ 1 = 'Installation'; 2 = 'Uninstallation'; 3 = 'Other' }
$Results = @{
    0 = 'NotStarted'
    1 = 'InProgress'
    2 = 'Succeeded'
    3 = 'SucceededWithErrors'
    4 = 'Failed'
    5 = 'Aborted'
}

# WU_E_UH_POSTREBOOTSTILLPENDING: the update is installed but waiting on a reboot to finish.
$PostRebootPending = 0x80242014

function New-EmptyResult {

    # Connect expects an object, so emit one with null values instead of nothing.
    [PSCustomObject]@{
        'Date'              = $null
        'Operation'         = $null
        'Result'            = $null
        'IsInstalled'       = $null
        'PendingReboot'     = $null
        'IsLatestEntry'     = $null
        'KB'                = $null
        'Title'             = $null
        'Description'       = $null
        'Categories'        = $null
        'ClientApplication' = $null
        'HResult'           = $null
        'UpdateId'          = $null
        'SupportUrl'        = $null
    }

}

if ( $Total -eq 0 ) {

    New-EmptyResult
    return

}

# The state of an update is decided by its newest history entry, so read the whole history
# before filtering or applying -Last.
$Entries = @($Searcher.QueryHistory(0, $Total)) | Sort-Object -Property 'Date' -Descending

$Latest = @{}
foreach ( $Entry in $Entries ) {

    $Id = $Entry.UpdateIdentity.UpdateID
    if ( -not $Latest.ContainsKey($Id) ) {

        $Latest[$Id] = $Entry

    }

}

$Output = foreach ( $Entry in $Entries ) {

    # Store app packages have a title like '9NRZT3Q9R3DL-Microsoft.WindowsAppRuntime.2'.
    $IsStoreApp = $Entry.Title -match '^[0-9A-Z]{12}-' -or $Entry.ClientApplicationID -like 'Acquisition;*'
    $IsDefinitionUpdate = $Entry.Title -match 'Security Intelligence Update|Definition Update'

    if ( ( $IsStoreApp -and -not $IncludeStoreApps ) -or ( $IsDefinitionUpdate -and -not $IncludeDefinitionUpdates ) ) {

        continue

    }

    $Newest = $Latest[$Entry.UpdateIdentity.UpdateID]

    [PSCustomObject]@{
        'Date'              = $Entry.Date
        'Operation'         = $Operations[[Int32]$Entry.Operation]
        'Result'            = $Results[[Int32]$Entry.ResultCode]

        # Based on the newest entry for this update, not this entry.
        'IsInstalled'       = [Bool]( $Newest.Operation -eq 1 -and $Newest.ResultCode -in 2, 3 )
        'PendingReboot'     = [Bool]( $Newest.ResultCode -eq 1 -and $Newest.HResult -eq $PostRebootPending )
        'IsLatestEntry'     = [Bool]( $Entry.Date -eq $Newest.Date )

        'KB'                = [regex]::Match($Entry.Title, 'KB\d+').Value
        'Title'             = $Entry.Title
        'Description'       = $Entry.Description
        'Categories'        = ( $Entry.Categories | ForEach-Object { $_.Name } ) -join '; '
        'ClientApplication' = $Entry.ClientApplicationID
        'HResult'           = '0x{0:X8}' -f $Entry.HResult
        'UpdateId'          = $Entry.UpdateIdentity.UpdateID
        'SupportUrl'        = $Entry.SupportUrl
    }

}

$Output = @($Output | Select-Object -First $Last)

if ( $Output.Count -eq 0 ) {

    New-EmptyResult
    return

}

$Output
