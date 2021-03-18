<#
.SYNOPSIS
    Evergreen Download & Setup Script for PowerShell Core Windows x64 MSI
.DESCRIPTION
    Evergreen Download & Setup Script for PowerShell Core Windows x64 MSI
    Created by Marco Hofmann in 2020
    Blog: https://www.meinekleinefarm.net/
    Twitter: @xenadmin
.EXAMPLE
    Start from inside the working directory, to preserve the Version history structure:
    PS C:\MDTBuildLab\Applications\Microsoft\PowerShell> .\Install_x86.ps1
.OUTPUTS
    Will generate a log file in C:\Windows\Temp
    Will generate an MSI archive in the Working directory with past versions.
.NOTES
    GitHub JSON API requires TLS 1.2 for Invoke-WebRequest.
    Ensure you uncomment the .NET command (line 39), if you haven't enabled TLS 1.2 in your Reference Image, yet.
.NOTES
    PowerShell Wrapper for MDT, Standalone and Chocolatey Installation - (C)2015 xenappblog.com 
    Example 1: Start-Process "XenDesktopServerSetup.exe" -ArgumentList $unattendedArgs -Wait -Passthru
    Example 2 Powershell: Start-Process powershell.exe -ExecutionPolicy bypass -file $Destination
    Example 3 EXE (Always use ' '):
    $UnattendedArgs='/qn'
    (Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode
    Example 4 MSI (Always use " "):
    $UnattendedArgs = "/i $PackageName.$InstallerType ALLUSERS=1 /qn /liewa $LogApp"
    (Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode
.LINK
    https://www.meinekleinefarm.net/download-and-install-latest-release-of-powershell/
.LINK
    https://github.com/xenadmin/applications/tree/master/Microsoft/PowerShell/
#>

Clear-Host
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

# Ensures that Invoke-WebRequest uses TLS 1.2 - UNCOMMENT if you haven't enabled TLS1.2 in your reference image and are using PowerShell < 7.0
# [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$arch = "x64"
$github = Invoke-WebRequest 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest' -UseBasicParsing | ConvertFrom-Json
$url = $($github.assets | Where-Object -Property name -Like "*win-$arch.msi").browser_download_url

$Vendor = "Microsoft"
$Product = "PowerShell"
$Version = $($github.tag_name).Trim("v")
$PackageName = "PowerShell-$Version-win-$arch"
$InstallerType = "msi"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:programfiles}" + "\$Product\"
$UnattendedArgs = "/i $PackageName.$InstallerType ALLUSERS=1 /qn /liewa $LogApp"

Start-Transcript $LogPS

if ( -Not (Test-Path -Path "$Version-$arch" ) ) {
    New-Item -ItemType directory -Path "$Version-$arch"
}

Set-Location "$Version-$arch"

Write-Verbose "Downloading $Vendor $Product $Version $arch" -Verbose
If (!(Test-Path -Path $Source)) {
    Invoke-WebRequest -Uri $url -OutFile $Source -UseBasicParsing
}
Else {
        Write-Verbose "File exists. Skipping Download." -Verbose
}

Write-Verbose "Starting Installation of $Vendor $Product $Version $arch" -Verbose
(Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Customization" -Verbose

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript