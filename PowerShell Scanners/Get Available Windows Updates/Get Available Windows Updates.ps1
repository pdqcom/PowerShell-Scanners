& '.\Install and Import Module.ps1' -ModuleName "PSWindowsUpdate"

# The Collection object this cmdlet emits is really weird.
# We have to assign it to a variable to get it to work properly in a pipeline.
$GWU = Get-WindowsUpdate

If ($null -ne $GWU) {
    $GWU | ForEach-Object {

        [PSCustomObject]@{
            "KB"                              = $_.KB
            "Title"                           = $_.Title
        
            # Convert to bytes so it will display properly in Inventory
            "Size"                            = [UInt64](Invoke-Expression $_.Size)

            "Status"                          = $_.Status
            "Description"                     = $_.Description
            "RebootRequired"                  = $_.RebootRequired
        
            # Indicates whether the update is flagged to be automatically selected by Windows Update.
            "AutoSelectOnWebSites"            = $_.AutoSelectOnWebSites

            "CanRequireSource"                = $_.CanRequireSource
            "Deadline"                        = $_.Deadline
            "DeltaCompressedContentAvailable" = $_.DeltaCompressedContentAvailable
            "DeltaCompressedContentPreferred" = $_.DeltaCompressedContentPreferred
            "EulaAccepted"                    = $_.EulaAccepted
            "IsBeta"                          = $_.IsBeta
            "IsDownloaded"                    = $_.IsDownloaded
            "IsHidden"                        = $_.IsHidden
            "IsInstalled"                     = $_.IsInstalled
            "IsMandatory"                     = $_.IsMandatory
            "IsPresent"                       = $_.IsPresent
            "IsUninstallable"                 = $_.IsUninstallable
            "UninstallationNotes"             = $_.UninstallationNotes
            "LastDeploymentChangeTime"        = $_.LastDeploymentChangeTime

            # Convert Decimal to 64-bit Integer
            "MaxDownloadSize"                 = [UInt64]$_.MaxDownloadSize
            "MinDownloadSize"                 = [UInt64]$_.MinDownloadSize

            "MsrcSeverity"                    = $_.MsrcSeverity
        
            # MHz
            "RecommendedCpuSpeed"             = $_.RecommendedCpuSpeed

            # https://docs.microsoft.com/en-us/windows/win32/api/wuapi/nf-wuapi-iupdate-get_recommendedharddiskspace
            "RecommendedHardDiskSpace"        = [UInt64]($_.RecommendedHardDiskSpace * 1MB)

            # https://docs.microsoft.com/en-us/windows/win32/api/wuapi/nf-wuapi-iupdate-get_recommendedmemory
            "RecommendedMemorySize"           = [UInt64]($_.RecommendedMemory * 1MB)

            "ReleaseNotes"                    = $_.ReleaseNotes
            "SupportUrl"                      = $_.SupportUrl

            # https://docs.microsoft.com/en-us/windows/win32/api/wuapi/ne-wuapi-updatetype
            "Type"                            = switch ($_.Type) {
                1 { "Software" }
                2 { "Driver" }
                Default { "Unknown" } 
            }

            "DeploymentAction"                = $_.DeploymentAction
            "DownloadPriority"                = $_.DownloadPriority
        
            # Indicates whether an update can be discovered only by browsing through the available updates.
            "BrowseOnly"                      = $_.BrowseOnly

            "PerUser"                         = $_.PerUser
            "AutoSelection"                   = $_.AutoSelection
            "AutoDownload"                    = $_.AutoDownload
        }
    }
}
else {
    [PSCustomObject]@{
        "KB"                              = $null
        "Title"                           = $null
        
        # Convert to bytes so it will display properly in Inventory
        "Size"                            = $null

        "Status"                          = $null
        "Description"                     = $null
        "RebootRequired"                  = $null
        
        # Indicates whether the update is flagged to be automatically selected by Windows Update.
        "AutoSelectOnWebSites"            = $null

        "CanRequireSource"                = $null
        "Deadline"                        = $null
        "DeltaCompressedContentAvailable" = $null
        "DeltaCompressedContentPreferred" = $null
        "EulaAccepted"                    = $null
        "IsBeta"                          = $null
        "IsDownloaded"                    = $null
        "IsHidden"                        = $null
        "IsInstalled"                     = $null
        "IsMandatory"                     = $null
        "IsPresent"                       = $null
        "IsUninstallable"                 = $null
        "UninstallationNotes"             = $null
        "LastDeploymentChangeTime"        = $null

        # Convert Decimal to 64-bit Integer
        "MaxDownloadSize"                 = $null
        "MinDownloadSize"                 = $null

        "MsrcSeverity"                    = $null
        
        # MHz
        "RecommendedCpuSpeed"             = $null

        # https://docs.microsoft.com/en-us/windows/win32/api/wuapi/nf-wuapi-iupdate-get_recommendedharddiskspace
        "RecommendedHardDiskSpace"        = $null

        # https://docs.microsoft.com/en-us/windows/win32/api/wuapi/nf-wuapi-iupdate-get_recommendedmemory
        "RecommendedMemorySize"           = $null

        "ReleaseNotes"                    = $null
        "SupportUrl"                      = $null

        # https://docs.microsoft.com/en-us/windows/win32/api/wuapi/ne-wuapi-updatetype
        "Type"                            = $null

        "DeploymentAction"                = $null
        "DownloadPriority"                = $null
        
        # Indicates whether an update can be discovered only by browsing through the available updates.
        "BrowseOnly"                      = $null

        "PerUser"                         = $null
        "AutoSelection"                   = $null
        "AutoDownload"                    = $null
    }
}