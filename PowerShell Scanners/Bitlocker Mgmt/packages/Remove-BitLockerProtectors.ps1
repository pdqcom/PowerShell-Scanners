<#
.SYNOPSIS
    PDQ Connect package - remove BitLocker key protectors from a drive.

.DESCRIPTION
    DESTRUCTIVE: removes the protectors named by -Protectors and/or -KeyProtectorId; does nothing if
    neither is given. To decrypt, use Disable-BitLocker.ps1.
    Guard: on an encrypted volume, a removal that would leave no RecoveryPassword (or no protector at
    all) is refused with a 'Failed' Guard row unless -Force $true; it also applies under -DryRun.
    Windows may still refuse to remove the last protector of some OS volumes.
    One row per action plus a final 'VolumeState' row; exits 1 on any failure.
    Requires the BitLocker module. Run as SYSTEM / local administrator. Windows PowerShell 5.1.

.PARAMETER DriveLetter
    Target drive, e.g. 'C:'. Default: the system drive.

.PARAMETER Protectors
    Comma separated types: Tpm, TpmPin, TpmStartupKey, TpmPinStartupKey, RecoveryPassword, Password,
    ExternalKey, TpmNetworkKey, PublicKey, AdAccountOrGroup, or All.
    RecoveryKey and StartupKey are aliases for ExternalKey.

.PARAMETER KeyProtectorId
    Comma separated protector IDs ({GUID}) to remove, e.g. one of several recovery passwords.

.PARAMETER Force
    $true allows leaving an encrypted volume without a RecoveryPassword (or any protector).

.PARAMETER DryRun
    $true = report only, change nothing.
#>
[CmdletBinding()]
param(
    [string]$DriveLetter = $env:SystemDrive,
    [string[]]$Protectors,
    [string[]]$KeyProtectorId,
    [bool]$Force = $false,
    [bool]$DryRun = $false
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]

function Add-Result([string]$Protector, [string]$Status, [string]$KeyProtectorId, [string]$Detail) {
    $script:results.Add([pscustomobject][ordered]@{
            ComputerName   = $env:COMPUTERNAME
            MountPoint     = $script:mountPoint
            Protector      = $Protector
            Status         = $Status
            KeyProtectorId = $KeyProtectorId
            Detail         = $Detail
        })
}

function Complete-Run {
    $results | Format-Table -AutoSize -Wrap | Out-String -Width 4096 | Write-Output
    if (@($results | Where-Object { $_.Status -eq 'Failed' }).Count -gt 0) { exit 1 }
    exit 0
}

# Some builds name the type NumericalPassword.
function Get-ProtectorType($keyProtector) {
    $protectorType = [string]$keyProtector.KeyProtectorType
    if ($protectorType -eq 'NumericalPassword') { 'RecoveryPassword' } else { $protectorType }
}

# ---- Normalise inputs ----
$mountPoint = $DriveLetter.Trim().TrimEnd('\')
if ($mountPoint.Length -eq 1) { $mountPoint = "${mountPoint}:" }
$aliases = @{ RecoveryKey = 'ExternalKey'; StartupKey = 'ExternalKey' }
$Protectors = @($Protectors | ForEach-Object { $_ -split '[,;\s]+' } | Where-Object { $_ } |
        ForEach-Object { if ($aliases.ContainsKey($_)) { $aliases[$_] } else { $_ } } | Select-Object -Unique)
$requestedIds = @($KeyProtectorId | ForEach-Object { $_ -split '[,;\s]+' } | Where-Object { $_ } | ForEach-Object { $_.Trim('{}') } | Select-Object -Unique)

$validTypes = 'Tpm', 'TpmPin', 'TpmStartupKey', 'TpmPinStartupKey', 'RecoveryPassword', 'Password', 'ExternalKey',
    'TpmNetworkKey', 'PublicKey', 'AdAccountOrGroup', 'All'

# ---- Pre-flight ----
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Add-Result 'Preflight' 'Failed' $null 'Must run elevated (administrator/SYSTEM).'; Complete-Run }

if (-not (Get-Command Remove-BitLockerKeyProtector -ErrorAction SilentlyContinue)) {
    Add-Result 'Preflight' 'Failed' $null 'BitLocker PowerShell module not available (feature missing or unsupported edition).'
    Complete-Run
}

if ($Protectors.Count -eq 0 -and $requestedIds.Count -eq 0) {
    Add-Result 'Preflight' 'Failed' $null 'Nothing requested. Specify -Protectors (e.g. RecoveryPassword or All) and/or -KeyProtectorId.'
    Complete-Run
}
$unknownTypes = @($Protectors | Where-Object { $_ -notin $validTypes })
if ($unknownTypes.Count -gt 0) { Add-Result 'Preflight' 'Failed' $null "Unknown protector type(s): $($unknownTypes -join ', '). Valid: $($validTypes -join ', ')"; Complete-Run }

try { $vol = Get-BitLockerVolume -MountPoint $mountPoint -ErrorAction Stop }
catch { Add-Result 'Preflight' 'Failed' $null "Volume $mountPoint not found: $($_.Exception.Message)"; Complete-Run }

if ([string]$vol.LockStatus -eq 'Locked') { Add-Result 'Preflight' 'Failed' $null "Volume $mountPoint is locked; unlock it first."; Complete-Run }

# ---- Select protectors ----
$current = @($vol.KeyProtector)
$targets = @($current | Where-Object {
        $Protectors -contains 'All' -or $Protectors -contains (Get-ProtectorType $_) -or $requestedIds -contains $_.KeyProtectorId.Trim('{}')
    })

if ($Protectors -contains 'All' -and $current.Count -eq 0) { Add-Result 'All' 'NothingToDo' $null 'Volume has no protectors.' }
foreach ($protectorType in $Protectors | Where-Object { $_ -ne 'All' }) {
    if (-not ($current | Where-Object { (Get-ProtectorType $_) -eq $protectorType })) { Add-Result $protectorType 'NotPresent' $null 'No protector of this type on the volume.' }
}
foreach ($requestedId in $requestedIds) {
    if (-not ($current | Where-Object { $_.KeyProtectorId.Trim('{}') -eq $requestedId })) { Add-Result 'KeyProtectorId' 'NotPresent' $requestedId 'No protector with this ID on the volume.' }
}

# ---- Safety guard ----
$remaining = @($current | Where-Object { $_.KeyProtectorId -notin $targets.KeyProtectorId })
$encrypted = [string]$vol.VolumeStatus -in 'FullyEncrypted', 'EncryptionInProgress', 'EncryptionPaused'
$dryRunLabel = if ($DryRun) { 'DRY RUN - ' } else { '' }
if ($targets.Count -gt 0 -and $encrypted -and -not $Force) {
    $reason = if ($remaining.Count -eq 0) { 'no protector at all' }
    elseif (-not ($remaining | Where-Object { (Get-ProtectorType $_) -eq 'RecoveryPassword' })) { 'no RecoveryPassword protector' }
    if ($reason) {
        Add-Result 'Guard' 'Failed' $null "${dryRunLabel}Refused: removal would leave the encrypted volume with $reason. Nothing removed. Use -Force `$true to override."
        $targets = @()
    }
}

# ---- Remove ----
$left = $current.Count
foreach ($keyProtector in $targets) {
    $type = Get-ProtectorType $keyProtector
    if ($DryRun) { Add-Result $type 'DryRun' $keyProtector.KeyProtectorId "${dryRunLabel}Would remove this protector."; continue }
    try {
        $null = Remove-BitLockerKeyProtector -MountPoint $mountPoint -KeyProtectorId $keyProtector.KeyProtectorId -Confirm:$false -ErrorAction Stop
        $left--
        Add-Result $type 'Removed' $keyProtector.KeyProtectorId 'Protector removed.'
    } catch {
        $hint = if ($left -eq 1) { ' This is the last protector; Windows may refuse to remove it (use Disable-BitLocker.ps1 to decrypt instead).' }
        Add-Result $type 'Failed' $keyProtector.KeyProtectorId "Remove-BitLockerKeyProtector failed: $($_.Exception.Message)$hint"
    }
}

# ---- Final state ----
try {
    $final = Get-BitLockerVolume -MountPoint $mountPoint -ErrorAction Stop
    $types = (@($final.KeyProtector | ForEach-Object { Get-ProtectorType $_ }) -join ', ')
    Add-Result 'VolumeState' 'Info' $null ("VolumeStatus=$($final.VolumeStatus); Protection=$($final.ProtectionStatus); " +
        "Encrypted=$($final.EncryptionPercentage)%; Protectors=[$types]")
} catch {
    Add-Result 'VolumeState' 'Failed' $null "Could not read final state: $($_.Exception.Message)"
}

Complete-Run
