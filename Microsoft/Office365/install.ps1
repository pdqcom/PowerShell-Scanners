<#
.SYNOPSIS
    Download and install latest Office 365 Deployment Tool (ODT)
.DESCRIPTION
    Download and install latest Office 365 Deployment Tool (ODT)
.EXAMPLE
    Set-Location to MDT script root aka %settings%
    PS C:\> . .\install.ps1
    Downloads latest officedeploymenttool.exe
    Creates a sub-directory for each new version
    Creates the offline cache for the setup files
    Installs Office 365 to target
.NOTES
    Author: Marco Hofmann & Trond Eric Haavarstein
    Twitter: @xenadmin & @xenappblog
    URL: https://www.meinekleinefarm.net & https://xenappblog.com/
.LINK
    https://www.meinekleinefarm.net/download-and-install-latest-office-365-deployment-tool-odt
.LINK
    https://www.microsoft.com/en-us/download/details.aspx?id=49117
.LINK
    https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117
#>

function Get-ODTUri {
    <#
        .SYNOPSIS
            Get Download URL of latest Office 365 Deployment Tool (ODT).
        .NOTES
            Author: Bronson Magnan
            Twitter: @cit_bronson
            Modified by: Marco Hofmann
            Twitter: @xenadmin
        .LINK
            https://www.meinekleinefarm.net/
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param ()

    $url = "https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117"
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $url -ErrorAction SilentlyContinue
    }
    catch {
        Throw "Failed to connect to ODT: $url with error $_."
        Break
    }
    finally {
        $ODTUri = $response.links | Where-Object {$_.outerHTML -like "*click here to download manually*"}
        Write-Output $ODTUri.href
    }
}

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

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$Vendor = "Microsoft"
$Product = "Office 365 x32"
$PackageName = "setup"
$InstallerType = "exe"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$Unattendedxml = 'RDSH.xml'
$UnattendedArgs = "/configure $Unattendedxml"
$UnattendedArgs2 = "/download $Unattendedxml"
$URL = $(Get-ODTUri)
$ProgressPreference = 'SilentlyContinue'

Start-Transcript $LogPS

Write-Verbose "Downloading latest version of Office 365 Deployment Tool (ODT)." -Verbose
Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile .\officedeploymenttool.exe
Write-Verbose "Read version number from downloaded file" -Verbose
$Version = (Get-Command .\officedeploymenttool.exe).FileVersionInfo.FileVersion

Write-Verbose "If downloaded ODT file is newer, create new sub-directory." -Verbose
if( -Not (Test-Path -Path $Version ) ) {
    New-Item -ItemType directory -Path $Version
    Copy-item ".\$Unattendedxml" -Destination $Version -Force
    .\officedeploymenttool.exe /quiet /extract:.\$Version
    start-sleep -s 5
    Write-Verbose "New folder created $Version" -Verbose
}
else {
    Write-Verbose "Version identical. Skipping folder creation." -Verbose
}

Set-Location $Version

Write-Verbose "Downloading $Vendor $Product via ODT $Version" -Verbose
if (!(Test-Path -Path .\Office\Data\v32.cab)) {
    (Start-Process "Setup.exe" -ArgumentList $unattendedArgs2 -Wait -Passthru).ExitCode
}
else {
    Write-Verbose "File exists. Skipping Download." -Verbose
}

Write-Verbose "Starting Installation of $Vendor $Product via ODT $Version" -Verbose
(Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Customization" -Verbose

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
