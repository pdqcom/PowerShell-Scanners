<#
.SYNOPSIS
    Evergreen Download & Setup Script for Microsoft Teams Machine Wide MSI Installer x64
.DESCRIPTION
    Evergreen Download & Setup Script for Microsoft Teams Machine Wide MSI Installer x64
    Created by Marco Hofmann in 2020
    Blog: https://www.meinekleinefarm.net/
    Twitter: @xenadmin
    The function Get-MsiProductVersion was copied from: https://gist.github.com/jstangroome/913062#gistcomment-3176459
.EXAMPLE
    Start from inside the working directory, to preserve the Version history structure:
    PS C:\MDTProduction\Applications\Microsoft\Teams> .\Install.ps1
.OUTPUTS
    Will generate a log file in C:\Windows\Temp
    Will generate an MSI archive in the Working directory with past versions.
.NOTES
    Microsoft Download Servers require TLS 1.2 for Invoke-WebRequest.
    Ensure you add the following .NET command to this script, if you haven't enabled TLS 1.2 in your Reference Image, yet.
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
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
    https://www.meinekleinefarm.net/download-and-install-latest-release-of-microsoft-teams-machine-wide-msi-x64/
.LINK
    https://github.com/xenadmin/applications/tree/master/Microsoft/Teams/
#>

function Get-MsiProductVersion {
    [CmdletBinding()]
    param (
    [Parameter(Mandatory=$true)]
    [string]
    $Path,
    [ref]
    $Result
    )
    if (!(Test-Path $Path)) {
    Write-Output "0.0.0.0"
    } else {
    #http://msdn.microsoft.com/en-us/library/aa369432(v=vs.85).aspx
    $job = start-job -scriptblock {
    param($Path)    
        function Get-Property ($Object, $PropertyName, [object[]]$ArgumentList) {
            return $Object.GetType().InvokeMember($PropertyName, 'Public, Instance, GetProperty', $null, $Object, $ArgumentList)
        }
        function Invoke-Method ($Object, $MethodName, $ArgumentList) {
            return $Object.GetType().InvokeMember($MethodName, 'Public, Instance, InvokeMethod', $null, $Object, $ArgumentList)
        }
        $ErrorActionPreference = 'Stop'
        Set-StrictMode -Version Latest
        $msiOpenDatabaseModeReadOnly = 0
        $Installer = New-Object -ComObject WindowsInstaller.Installer
        $Database = Invoke-Method $Installer OpenDatabase  @($Path, $msiOpenDatabaseModeReadOnly) -ErrorAction SilentlyContinue
        if ($null -ne $Database) {
            $View = Invoke-Method $Database OpenView  @("SELECT Value FROM Property WHERE Property='ProductVersion'")
            Invoke-Method $View Execute
            $Record = Invoke-Method $View Fetch
            if ($Record) {
                Write-Output (Get-Property $Record StringData 1)
            }
            Invoke-Method $View Close @()
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Database) | Out-Null
        }
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Installer) | Out-Null
        Remove-Variable -Name Record, View, Database, Installer
        [System.GC]::Collect()
    } -argumentlist @($Path)
    $job | wait-job
    $Output = Receive-Job $job -ErrorAction Stop
    $Result.Value = $Output[1]
    Remove-job $job
    Write-Output $Result.Value
    }
}

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$Vendor = "Microsoft"
$Product = "Teams Machine Wide Installer x64"
# $Version = Get-Content ".\last_version.txt"
$PackageName = "Teams_windows_x64"
$InstallerType = "msi"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$UnattendedArgs = "/i $PackageName.$InstallerType /qn /liewa $LogApp /norestart OPTIONS=`"noAutoStart=true`" ALLUSER=1 ALLUSERS=1"

$url = "https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&download=true&managedInstaller=true&arch=x64"
# $url = "https://aka.ms/teams64bitmsi"

Start-Transcript $LogPS

Write-Verbose "Downloading $Vendor $Product" -Verbose
Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $Source

Write-Verbose "Getting Version Number from MSI" -Verbose
$Version = $null
Get-MsiProductVersion -Path $(Get-ChildItem $source).FullName -Result ([ref]$Version)
Write-Verbose "Version: $Version" -Verbose

Write-Verbose "Set or Get Version number from last_version.txt" -Verbose
if ($Version) { 
    Write-Verbose "Set from MSI" -Verbose
    $Version | Out-File -FilePath ".\last_version.txt" -Force
    }
else {
    Write-Verbose "Get from TXT" -Verbose
    $Version = Get-Content ".\last_version.txt"
}

if ( -Not ( Test-Path -Path $($Version.ToString()) ) )
{
    Write-Verbose "Create new sub directory $Version" -Verbose
    New-Item -ItemType directory -Path "$Version"
    Move-Item $Source ".\$Version\$Source" -Force
} 
else {
    Write-Verbose "Directory already exists" -Verbose
    Remove-Item $Source -Force
}

Set-Location $Version

Write-Verbose "Starting Installation of $Vendor $Product $Version" -Verbose
(Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Customization" -Verbose
# (Get-Content ${ENV:ProgramFiles(x86)}'\Teams Installer\setup.json').replace('false','true') | Set-Content ${ENV:PROGRAMFILES(x86)}'\Teams Installer\setup.json'

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript