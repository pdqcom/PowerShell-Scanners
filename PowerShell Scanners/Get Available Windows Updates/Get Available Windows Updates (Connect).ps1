# Self-contained version for PDQ Connect. Uses the built-in Windows Update COM API,
# so there is no module to install.
[CmdletBinding()]
param (
    # Search the Windows Update service instead of the device's configured update source (such as WSUS).
    [Switch]$WindowsUpdate
)

$Searcher = (New-Object -ComObject 'Microsoft.Update.Session').CreateUpdateSearcher()

if ( $WindowsUpdate ) {

    # ssWindowsUpdate
    $Searcher.ServerSelection = 2

}

$Updates = $Searcher.Search('IsInstalled=0 and IsHidden=0').Updates

if ( $Updates.Count -eq 0 ) {

    # Connect expects an object, so emit one with null values instead of nothing.
    [PSCustomObject]@{
        'KB'                       = $null
        'Title'                    = $null
        'Size'                     = $null
        'Description'              = $null
        'RebootRequired'           = $null
        'EulaAccepted'             = $null
        'IsBeta'                   = $null
        'IsDownloaded'             = $null
        'IsHidden'                 = $null
        'IsInstalled'              = $null
        'IsMandatory'              = $null
        'IsUninstallable'          = $null
        'Deadline'                 = $null
        'LastDeploymentChangeTime' = $null
        'MsrcSeverity'             = $null
        'RecommendedCpuSpeed'      = $null
        'RecommendedHardDiskSpace' = $null
        'RecommendedMemorySize'    = $null
        'ReleaseNotes'             = $null
        'SupportUrl'               = $null
        'Type'                     = $null
        'DeploymentAction'         = $null
        'DownloadPriority'         = $null
        'BrowseOnly'               = $null
        'PerUser'                  = $null
        'AutoSelectOnWebSites'     = $null
    }
    return

}

$Updates | ForEach-Object {

    [PSCustomObject]@{
        'KB'                       = $_.KBArticleIDs -join ', '
        'Title'                    = $_.Title
        'Size'                     = [UInt64]$_.MaxDownloadSize
        'Description'              = $_.Description
        'RebootRequired'           = $_.RebootRequired
        'EulaAccepted'             = $_.EulaAccepted
        'IsBeta'                   = $_.IsBeta
        'IsDownloaded'             = $_.IsDownloaded
        'IsHidden'                 = $_.IsHidden
        'IsInstalled'              = $_.IsInstalled
        'IsMandatory'              = $_.IsMandatory
        'IsUninstallable'          = $_.IsUninstallable
        'Deadline'                 = $_.Deadline
        'LastDeploymentChangeTime' = $_.LastDeploymentChangeTime
        'MsrcSeverity'             = $_.MsrcSeverity
        'RecommendedCpuSpeed'      = $_.RecommendedCpuSpeed
        'RecommendedHardDiskSpace' = [UInt64]($_.RecommendedHardDiskSpace * 1MB)
        'RecommendedMemorySize'    = [UInt64]($_.RecommendedMemory * 1MB)
        'ReleaseNotes'             = $_.ReleaseNotes
        'SupportUrl'               = $_.SupportUrl
        'Type'                     = switch ( $_.Type ) { 1 { 'Software' } 2 { 'Driver' } default { 'Unknown' } }
        'DeploymentAction'         = $_.DeploymentAction
        'DownloadPriority'         = $_.DownloadPriority
        'BrowseOnly'               = $_.BrowseOnly
        'PerUser'                  = $_.PerUser
        'AutoSelectOnWebSites'     = $_.AutoSelectOnWebSites
    }

}
