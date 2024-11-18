[CmdletBinding()]
param (
    [Parameter(Mandatory = 'True')]
    [String]$Name,
    [String]$Description
)

$null = Copy-Item -Path '.\_Template' -Destination ".\$Name" -Recurse

Set-Location ".\$Name"

Rename-Item -Path ".\Template.ps1" -NewName ".\$Name.ps1"

[XML]$ScanProfile = Get-Content '.\Scan Profile.xml'

$ScanProfile.'AdminArsenal.Export'.ScanProfile.Name = "PS - $Name"
$ScanProfile.'AdminArsenal.Export'.ScanProfile.Scanners.Scanner.ModifiedDate = [String](Get-Date -Format 'o')
$ScanProfile.'AdminArsenal.Export'.ScanProfile.Scanners.Scanner.Name = $Name
$ScanProfile.'AdminArsenal.Export'.ScanProfile.Scanners.Scanner.UID = (New-Guid) -replace '-'
$ScanProfile.'AdminArsenal.Export'.ScanProfile.Scanners.Scanner.FileName = "C:\PowerShell-Scanners\PowerShell Scanners\$Name\$Name.ps1"

if($Description) {
    $ScanProfile.'AdminArsenal.Export'.ScanProfile.Description = $Description
}

$ScanProfile.Save("$PWD\Scan Profile.xml")

if (!$Description) {
    Write-Warning "Don't forget to update the Description in 'Scan Profile.xml'!"
}