# Self-contained version for PDQ Connect. Uses the built-in Windows Update COM API,
# so there is no module to install and no Scanner.log to read.
[CmdletBinding()]
param (
    # Maximum number of history entries to return, newest first.
    [UInt32]$Last = 100
)

$Searcher = (New-Object -ComObject 'Microsoft.Update.Session').CreateUpdateSearcher()
$Count = [Math]::Min($Last, $Searcher.GetTotalHistoryCount())

$Operations = @{ 1 = 'Installation'; 2 = 'Uninstallation'; 3 = 'Other' }
$Results = @{
    0 = 'NotStarted'
    1 = 'InProgress'
    2 = 'Succeeded'
    3 = 'SucceededWithErrors'
    4 = 'Failed'
    5 = 'Aborted'
}

if ( $Count -eq 0 ) {

    Write-Output 'No Windows Update history found.'
    return

}

$Searcher.QueryHistory(0, $Count) | ForEach-Object {

    [PSCustomObject]@{
        'Date'        = $_.Date
        'Operation'   = $Operations[[Int32]$_.Operation]
        'Result'      = $Results[[Int32]$_.ResultCode]
        'KB'          = [regex]::Match($_.Title, 'KB\d+').Value
        'Title'       = $_.Title
        'Description' = $_.Description
        'HResult'     = '0x{0:X8}' -f $_.HResult
        'UpdateId'    = $_.UpdateIdentity.UpdateID
        'SupportUrl'  = $_.SupportUrl
    }

}
