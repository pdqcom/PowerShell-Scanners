<#
.SYNOPSIS
    PDQ Connect package - add BitLocker protectors to a drive and start encryption.

.DESCRIPTION
    Adds the requested protectors and, if the volume is fully decrypted, starts encryption with
    the first one. Idempotent: existing protector types are reported as 'AlreadyPresent'.
    One row per action plus a final 'VolumeState' row; exits 1 on any failure.
    Requires the BitLocker module. The OS drive and the Tpm / TpmPin protectors also need a present,
    ready TPM (see Set-TpmReady.ps1); without one the run stops before adding anything.
    Run as SYSTEM / local administrator. Windows PowerShell 5.1.

.PARAMETER DriveLetter
    Target drive, e.g. 'C:'. Default: the system drive.

.PARAMETER Protectors
    Comma separated, default Tpm,RecoveryPassword. Tpm and TpmPin can't be combined.
      Tpm              TPM only
      TpmPin           TPM + startup PIN (-Pin; startup authentication policy must allow it)
      RecoveryPassword 48-digit numerical password
      Password         Passphrase (-Password)

.PARAMETER Pin / Password
    PLAINTEXT: visible to anyone who can view the PDQ package and its parameters.

.PARAMETER EncryptionMethod
    Aes128, Aes256, XtsAes128, XtsAes256 (default). Used only when encryption starts.

.PARAMETER UsedSpaceOnly / SkipHardwareTest
    Default $true. SkipHardwareTest avoids the restart-and-test cycle on OS drives.

.PARAMETER BackupToAD / BackupToEntra
    Escrow every RecoveryPassword on the drive to AD DS / Entra ID afterwards.

.PARAMETER ReturnRecoveryPassword
    Include the recovery password in the output. Default $false: output is kept in PDQ logs.

.PARAMETER DryRun
    $true = report only, change nothing.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Justification = 'PDQ passes package parameters as text')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'ReturnRecoveryPassword', Justification = 'Used inside Add-Result')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'BitLocker cmdlets need a SecureString')]
[CmdletBinding()]
param(
    [string]$DriveLetter = $env:SystemDrive,
    [string[]]$Protectors = @('Tpm', 'RecoveryPassword'),
    [string]$Pin = $null,
    [string]$Password = $null,
    [ValidateSet('Aes128', 'Aes256', 'XtsAes128', 'XtsAes256')]
    [string]$EncryptionMethod = 'XtsAes256',
    [bool]$UsedSpaceOnly = $false,
    [bool]$SkipHardwareTest = $true,
    [bool]$BackupToAD = $false,
    [bool]$BackupToEntra = $false,
    [bool]$ReturnRecoveryPassword = $true,
    [bool]$DryRun = $false
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]

function Add-Result([string]$Protector, [string]$Status, [string]$KeyProtectorId, [string]$Detail, [string]$Secret) {
    $row = [ordered]@{
        ComputerName   = $env:COMPUTERNAME
        MountPoint     = $script:mountPoint
        Protector      = $Protector
        Status         = $Status
        KeyProtectorId = $KeyProtectorId
        Detail         = $Detail
    }
    if ($ReturnRecoveryPassword) { $row['RecoveryPassword'] = $Secret }
    $script:results.Add([pscustomobject]$row)
}

function Complete-Run {
    $results | Format-Table -AutoSize -Wrap | Out-String -Width 4096 | Write-Output
    if (@($results | Where-Object { $_.Status -eq 'Failed' }).Count -gt 0) { exit 1 }
    exit 0
}

# ---- Normalise inputs ----
$mountPoint = $DriveLetter.Trim().TrimEnd('\')
if ($mountPoint.Length -eq 1) { $mountPoint = "${mountPoint}:" }
$Protectors = @($Protectors | ForEach-Object { $_ -split '[,;\s]+' } | Where-Object { $_ })

$valid = 'Tpm', 'TpmPin', 'RecoveryPassword', 'Password'
# Order matters when volume is decrypted: the first protector is used to start encryption.
$priority = 'Tpm', 'TpmPin', 'Password', 'RecoveryPassword'
$typeMap = @{ Tpm = 'Tpm'; TpmPin = 'TpmPin'; RecoveryPassword = 'RecoveryPassword'; Password = 'Password' }

# ---- Pre-flight ----
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Add-Result 'Preflight' 'Failed' $null 'Must run elevated (administrator/SYSTEM).' $null; Complete-Run }

if (-not (Get-Command Enable-BitLocker -ErrorAction SilentlyContinue)) {
    Add-Result 'Preflight' 'Failed' $null 'BitLocker PowerShell module not available (feature missing or unsupported edition).' $null
    Complete-Run
}

$unknownProtectors = @($Protectors | Where-Object { $_ -notin $valid })
if ($unknownProtectors.Count -gt 0) { Add-Result 'Preflight' 'Failed' $null "Unknown protector(s): $($unknownProtectors -join ', '). Valid: $($valid -join ', ')" $null; Complete-Run }
if ($Protectors.Count -eq 0) { Add-Result 'Preflight' 'Failed' $null 'No protectors requested.' $null; Complete-Run }
if ($Protectors -contains 'Tpm' -and $Protectors -contains 'TpmPin') {
    Add-Result 'Preflight' 'Failed' $null "'Tpm' and 'TpmPin' cannot be combined; choose one." $null; Complete-Run
}
if ($Protectors -contains 'TpmPin' -and -not $Pin) { Add-Result 'TpmPin' 'Failed' $null '-Pin is required.' $null; Complete-Run }
if ($Protectors -contains 'Password' -and -not $Password) { Add-Result 'Password' 'Failed' $null '-Password is required.' $null; Complete-Run }

try { $vol = Get-BitLockerVolume -MountPoint $mountPoint -ErrorAction Stop }
catch { Add-Result 'Preflight' 'Failed' $null "Volume $mountPoint not found: $($_.Exception.Message)" $null; Complete-Run }

# The OS drive and the TPM protectors need a present, ready TPM; stop before adding anything
if ($mountPoint -ieq $env:SystemDrive -or $Protectors -contains 'Tpm' -or $Protectors -contains 'TpmPin') {
    $tpmMsg = $null
    if (-not (Get-Command Get-Tpm -ErrorAction SilentlyContinue)) { $tpmMsg = 'TrustedPlatformModule module (Get-Tpm) not available' }
    else {
        try {
            $tpm = Get-Tpm -ErrorAction Stop
            if (-not ($tpm.TpmPresent -and $tpm.TpmReady)) { $tpmMsg = "present=$($tpm.TpmPresent) ready=$($tpm.TpmReady); run Set-TpmReady.ps1" }
        } catch { $tpmMsg = "Get-Tpm failed: $($_.Exception.Message)" }
    }
    if ($tpmMsg) { Add-Result 'Preflight' 'Failed' $null "TPM not usable: $tpmMsg" $null; Complete-Run }
}

function Get-ProtectorParameter([string]$name) {
    switch ($name) {
        'Tpm' { @{ TpmProtector = $true } }
        'TpmPin' { @{ TpmAndPinProtector = $true; Pin = (ConvertTo-SecureString $Pin -AsPlainText -Force) } }
        'RecoveryPassword' { @{ RecoveryPasswordProtector = $true } }
        'Password' { @{ PasswordProtector = $true; Password = (ConvertTo-SecureString $Password -AsPlainText -Force) } }
    }
}

function Get-ProtectorSnapshot { @((Get-BitLockerVolume -MountPoint $mountPoint).KeyProtector) }

function Find-NewProtector($beforeIds, [string]$expectedType) {
    Get-ProtectorSnapshot | Where-Object { $_.KeyProtectorId -notin $beforeIds -and [string]$_.KeyProtectorType -eq $expectedType } |
        Select-Object -First 1
}

# ---- Work out what is missing ----
$existingTypes = @($vol.KeyProtector | ForEach-Object { [string]$_.KeyProtectorType })
$ordered = @($priority | Where-Object { $_ -in $Protectors })
$toAdd = New-Object System.Collections.Generic.List[string]
foreach ($protectorType in $ordered) {
    if ($existingTypes -contains $typeMap[$protectorType]) {
        $existing = $vol.KeyProtector | Where-Object { [string]$_.KeyProtectorType -eq $typeMap[$protectorType] } | Select-Object -First 1
        Add-Result $protectorType 'AlreadyPresent' $existing.KeyProtectorId 'Protector type already exists; no change.' $existing.RecoveryPassword
    } else { $toAdd.Add($protectorType) }
}

# ---- Start encryption (decrypted volume) using the first protector, then add the rest ----
$dryRunLabel = if ($DryRun) { 'DRY RUN - ' } else { '' }
$decrypted = ([string]$vol.VolumeStatus -eq 'FullyDecrypted')
if ($decrypted -and $toAdd.Count -eq 0) {
    Add-Result 'Encryption' 'Failed' $null 'Volume is decrypted and no usable protector could be added, so encryption was not started.' $null
} elseif ($decrypted -and $DryRun) {
    Add-Result $toAdd[0] 'DryRun' $null "${dryRunLabel}Would add this protector and start encryption ($EncryptionMethod, UsedSpaceOnly=$UsedSpaceOnly)." $null
    $toAdd = @($toAdd | Select-Object -Skip 1)
} elseif ($decrypted) {
    $primary = $toAdd[0]
    $before = @(Get-ProtectorSnapshot | ForEach-Object { $_.KeyProtectorId })
    try {
        $splat = @{ MountPoint = $mountPoint; EncryptionMethod = $EncryptionMethod; UsedSpaceOnly = $UsedSpaceOnly
            SkipHardwareTest = $SkipHardwareTest; ErrorAction = 'Stop'
        } + (Get-ProtectorParameter $primary)
        $null = Enable-BitLocker @splat
        $newProtector = Find-NewProtector $before $typeMap[$primary]
        Add-Result $primary 'Enabled' $newProtector.KeyProtectorId "Encryption started ($EncryptionMethod, UsedSpaceOnly=$UsedSpaceOnly)." $newProtector.RecoveryPassword
    } catch {
        Add-Result $primary 'Failed' $null "Enable-BitLocker failed: $($_.Exception.Message)" $null
    }
    $toAdd = @($toAdd | Select-Object -Skip 1)
}

foreach ($protectorType in $toAdd) {
    if ($DryRun) { Add-Result $protectorType 'DryRun' $null "${dryRunLabel}Would add this protector." $null; continue }
    $before = @(Get-ProtectorSnapshot | ForEach-Object { $_.KeyProtectorId })
    try {
        $splat = @{ MountPoint = $mountPoint; ErrorAction = 'Stop' } + (Get-ProtectorParameter $protectorType)
        $null = Add-BitLockerKeyProtector @splat
        $newProtector = Find-NewProtector $before $typeMap[$protectorType]
        Add-Result $protectorType 'Added' $newProtector.KeyProtectorId 'Protector added.' $newProtector.RecoveryPassword
    } catch {
        Add-Result $protectorType 'Failed' $null "Add-BitLockerKeyProtector failed: $($_.Exception.Message)" $null
    }
}

# ---- Escrow recovery passwords ----
if (($BackupToAD -or $BackupToEntra) -and $DryRun) {
    $escrowTargets = (@(if ($BackupToAD) { 'Active Directory' }; if ($BackupToEntra) { 'Entra ID' })) -join ' and '
    Add-Result 'Backup' 'DryRun' $null "${dryRunLabel}Would back up every RecoveryPassword on the volume (existing and newly added) to $escrowTargets." $null
} elseif ($BackupToAD -or $BackupToEntra) {
    $recovery = @(Get-ProtectorSnapshot | Where-Object { [string]$_.KeyProtectorType -eq 'RecoveryPassword' })
    if ($recovery.Count -eq 0) {
        Add-Result 'Backup' 'Skipped' $null 'No RecoveryPassword protector on the volume to back up.' $null
    }
    foreach ($recoveryProtector in $recovery) {
        if ($BackupToAD) {
            try {
                $null = Backup-BitLockerKeyProtector -MountPoint $mountPoint -KeyProtectorId $recoveryProtector.KeyProtectorId -ErrorAction Stop
                Add-Result 'RecoveryPassword.BackupAD' 'Backed up' $recoveryProtector.KeyProtectorId 'Escrowed to Active Directory.' $null
            } catch { Add-Result 'RecoveryPassword.BackupAD' 'Failed' $recoveryProtector.KeyProtectorId $_.Exception.Message $null }
        }
        if ($BackupToEntra) {
            try {
                $null = BackupToAAD-BitLockerKeyProtector -MountPoint $mountPoint -KeyProtectorId $recoveryProtector.KeyProtectorId -ErrorAction Stop
                Add-Result 'RecoveryPassword.BackupEntra' 'Backed up' $recoveryProtector.KeyProtectorId 'Escrowed to Entra ID.' $null
            } catch { Add-Result 'RecoveryPassword.BackupEntra' 'Failed' $recoveryProtector.KeyProtectorId $_.Exception.Message $null }
        }
    }
}

# ---- Final state ----
try {
    $final = Get-BitLockerVolume -MountPoint $mountPoint
    $types = (@($final.KeyProtector | ForEach-Object { [string]$_.KeyProtectorType }) -join ', ')
    Add-Result 'VolumeState' 'Info' $null ("VolumeStatus=$($final.VolumeStatus); Protection=$($final.ProtectionStatus); " +
        "Encrypted=$($final.EncryptionPercentage)%; Method=$($final.EncryptionMethod); Protectors=[$types]") $null
} catch {
    Add-Result 'VolumeState' 'Failed' $null "Could not read final state: $($_.Exception.Message)" $null
}

Complete-Run
