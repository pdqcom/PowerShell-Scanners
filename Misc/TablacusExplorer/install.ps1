# Tablacus Explorer modifications made by Marco Hofmann 2019 (https://www.meinekleinefarm.net/download-and-install-latest-tablacus-explorer)

<#
PowerShell Wrapper for MDT, Standalone and Chocolatey Installation - (C)2015 xenappblog.com 
Example 1: Start-Process "XenDesktopServerSetup.exe" -ArgumentList $unattendedArgs -Wait -Passthru
Example 2 Powershell: Start-Process powershell.exe -ExecutionPolicy bypass -file $Destination
Example 3 EXE (Always use ' '):
$UnattendedArgs='/qn'
(Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode
Example 4 MSI (Always use " "):
$UnattendedArgs = "/i $PackageName.$InstallerType ALLUSERS=1 /qn /liewa $LogApp"
(Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode
#>

Clear-Host
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

# Tablacus specific commands
# Ensures that Invoke-WebRequest uses TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$te = Invoke-WebRequest 'https://api.github.com/repos/tablacus/tablacusexplorer/releases/latest' | ConvertFrom-Json
$url = "https://tablacus.github.io/TablacusExplorerAddons/te/te.zip"

$Vendor = "Misc"
$Product = "TablacusExplorer"
$PackageName = "te"
$Version = $te.tag_name
$InstallerType = "zip"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:programfiles}" + "\$Product\"
#$UnattendedArgs = '/VERYSILENT /SUPPRESSMESSAGEBOXES /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /NORESTART'
#$UnattendedArgs = '/SP- /VERYSILENT /SUPPRESSMSGBOXES /CLOSEAPPLICATIONS /NORESTART'
$ProgressPreference = 'SilentlyContinue'

Start-Transcript $LogPS

if ( -Not (Test-Path -Path $Version ) ) {
    New-Item -ItemType directory -Path $Version
}

Set-Location $Version

Write-Verbose "Downloading $Vendor $Product $Version" -Verbose
If (!(Test-Path -Path $Source)) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $Source
    }
    Else {
            Write-Verbose "File exists. Skipping Download." -Verbose
    }

Write-Verbose "Starting Installation of $Vendor $Product $Version" -Verbose
if (Get-Process 'te64.exe' -ea SilentlyContinue) {Stop-Process -processname te64.exe}
Expand-Archive -Path $Source -DestinationPath $Destination

Write-Verbose "Customization" -Verbose

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
