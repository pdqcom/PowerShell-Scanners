<#
.SYNOPSIS
    PDQ Connect package - decrypt a BitLocker volume.

.DESCRIPTION
    DESTRUCTIVE: runs Disable-BitLocker, which removes all key protectors and decrypts in the
    background; the final 'VolumeState' row shows progress. To remove single protectors use
    Remove-BitLockerProtectors.ps1.
    Already decrypted: 'NothingToDo'. Decryption running: 'InProgress'. Locked volume: 'Failed'.
    A volume with protection On is refused unless -Force $true.
    One row per action plus a final 'VolumeState' row; exits 1 on any failure.
    Requires the BitLocker module. Run as SYSTEM / local administrator. Windows PowerShell 5.1.

.PARAMETER DriveLetter
    Target drive, e.g. 'C:'. Default: the system drive.

.PARAMETER Force
    $true allows decrypting a volume whose protection is On.

.PARAMETER DryRun
    $true = report only, change nothing.
#>
[CmdletBinding()]
param(
    [string]$DriveLetter = $env:SystemDrive,
    [bool]$Force = $false,
    [bool]$DryRun = $false
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]

function Add-Result([string]$Action, [string]$Status, [string]$Detail) {
    $script:results.Add([pscustomobject][ordered]@{
            ComputerName = $env:COMPUTERNAME
            MountPoint   = $script:mountPoint
            Action       = $Action
            Status       = $Status
            Detail       = $Detail
        })
}

function Complete-Run {
    $results | Format-Table -AutoSize -Wrap | Out-String -Width 4096 | Write-Output
    if (@($results | Where-Object { $_.Status -eq 'Failed' }).Count -gt 0) { exit 1 }
    exit 0
}

function Add-VolumeState {
    try {
        $finalVolume = Get-BitLockerVolume -MountPoint $mountPoint -ErrorAction Stop
        $types = (@($finalVolume.KeyProtector | ForEach-Object { [string]$_.KeyProtectorType }) -join ', ')
        Add-Result 'VolumeState' 'Info' ("VolumeStatus=$($finalVolume.VolumeStatus); Protection=$($finalVolume.ProtectionStatus); " +
            "Encrypted=$($finalVolume.EncryptionPercentage)%; Protectors=[$types]")
    } catch {
        Add-Result 'VolumeState' 'Failed' "Could not read final state: $($_.Exception.Message)"
    }
}

# ---- Normalise inputs ----
$mountPoint = $DriveLetter.Trim().TrimEnd('\')
if ($mountPoint.Length -eq 1) { $mountPoint = "${mountPoint}:" }

# ---- Pre-flight ----
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Add-Result 'Preflight' 'Failed' 'Must run elevated (administrator/SYSTEM).'; Complete-Run }

# The cmdlet, not this script (same name)
$disable = Get-Command Disable-BitLocker -CommandType Cmdlet, Function -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $disable) {
    Add-Result 'Preflight' 'Failed' 'BitLocker PowerShell module not available (feature missing or unsupported edition).'
    Complete-Run
}

try { $vol = Get-BitLockerVolume -MountPoint $mountPoint -ErrorAction Stop }
catch { Add-Result 'Preflight' 'Failed' "Volume $mountPoint not found: $($_.Exception.Message)"; Complete-Run }

# ---- Decide ----
$status = [string]$vol.VolumeStatus
$dryRunLabel = if ($DryRun) { 'DRY RUN - ' } else { '' }

if ([string]$vol.LockStatus -eq 'Locked') {
    Add-Result 'Decrypt' 'Failed' "Volume $mountPoint is locked; unlock it first (Unlock-BitLocker) and run again."
} elseif ($status -eq 'FullyDecrypted') {
    Add-Result 'Decrypt' 'NothingToDo' 'Volume is already fully decrypted.'
} elseif ($status -eq 'DecryptionInProgress') {
    Add-Result 'Decrypt' 'InProgress' "Decryption already running ($($vol.EncryptionPercentage)% still encrypted)."
} elseif ([string]$vol.ProtectionStatus -eq 'On' -and -not $Force) {
    Add-Result 'Decrypt' 'Failed' "${dryRunLabel}Refused: protection is On. Use -Force `$true to decrypt a protected volume."
} elseif ($DryRun) {
    Add-Result 'Decrypt' 'DryRun' "${dryRunLabel}Would decrypt (status: $status, protection: $($vol.ProtectionStatus), $($vol.EncryptionPercentage)% encrypted)."
} else {
    try {
        $null = & $disable -MountPoint $mountPoint -ErrorAction Stop
        Add-Result 'Decrypt' 'Started' 'Decryption started; it runs in the background and all protectors are removed.'
    } catch {
        Add-Result 'Decrypt' 'Failed' "Disable-BitLocker failed: $($_.Exception.Message)"
    }
}

Add-VolumeState
Complete-Run
