[cmdletBinding()]
param(
    [ValidateSet('KB','MB','GB')]
    [string]
    $In = 'MB'
)

$ErrorActionPreference = "SilentlyContinue"

$UserFolders = Get-ChildItem -Path "C:\Users" -Force -Directory

ForEach ( $Folder in $UserFolders ) {

    $FolderSize = ( Get-Childitem -Path $Folder.FullName -Force -Recurse | Measure-Object -Property "Length" -Sum ).Sum
    
    switch($In){
        'KB' {$FriendlySize = "$([math]::Round(($FolderSize /1KB),2)) KB"}
        'MB' {$FriendlySize = "$([math]::Round(($FolderSize /1MB),2)) MB"}
        'GB' {$FriendlySize = "$([math]::Round(($FolderSize /1GB),2)) GB"}
    }
    
    [PSCustomObject]@{
        FolderName    = $Folder.BaseName
        FolderPath    = $Folder.FullName
        Size          = $FolderSize
        FriendlySize  = $FriendlySize
    }

}