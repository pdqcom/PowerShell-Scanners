<#
.SYNOPSIS
    PDQ Connect scanner: BitLocker volume status and key protectors.

.DESCRIPTION
    Emits one object per volume, or one explanatory row when Get-BitLockerVolume can't be run
    or returns no volumes. Needs the BitLocker PowerShell module. Coded values are shown as
    "Name (value)".

    BitLockerQueryStatus is Ok, NoVolumes, ModuleMissing, AccessDenied, ProviderError or
    ScriptError. BitLockerError and BitLockerNextStep explain a failure; BitLockerWarnings
    lists per-volume problems, and the affected fields are $null.

    TpmEnabled and TpmReady (from Get-Tpm) repeat on every row. Both are $false when the TPM is
    missing or can't be read; the reason is added to BitLockerWarnings.

    Run as SYSTEM or a local administrator. Compatible with Windows PowerShell 5.1.
#>

$ErrorActionPreference = 'Stop'

$ProtectionNames = @{ 0 = 'Off'; 1 = 'On'; 2 = 'Unknown' }
$ConversionNames = @{ 0 = 'FullyDecrypted'; 1 = 'FullyEncrypted'; 2 = 'EncryptionInProgress'
    3 = 'DecryptionInProgress'; 4 = 'EncryptionPaused'; 5 = 'DecryptionPaused'
}
$MethodNames     = @{ 0 = 'None'; 1 = 'Aes128Diffuser'; 2 = 'Aes256Diffuser'; 3 = 'Aes128'
    4 = 'Aes256'; 5 = 'Hardware'; 6 = 'XtsAes128'; 7 = 'XtsAes256'
}
$LockNames       = @{ 0 = 'Unlocked'; 1 = 'Locked' }
$ProtectorNames  = @{ 0 = 'Unknown'; 1 = 'Tpm'; 2 = 'ExternalKey'; 3 = 'RecoveryPassword'; 4 = 'TpmPin'
    5 = 'TpmStartupKey'; 6 = 'TpmPinStartupKey'; 7 = 'PublicKey'; 8 = 'Password'
    9 = 'TpmCertificate'; 10 = 'CryptoApiNextGeneration'
}
$TpmProtectorTypes = 1, 4, 5, 6, 9

$NextSteps = @{
    AccessDenied  = 'Get-BitLockerVolume requires administrator rights. Run the scanner as SYSTEM or a local administrator (see ScannerRunAs / ScannerElevated in this output) and rescan.'
    ModuleMissing = 'The BitLocker PowerShell module is not available. On Windows Server install the feature (Install-WindowsFeature BitLocker -IncludeManagementTools, then reboot). On a client, confirm the Windows edition includes BitLocker.'
    ProviderError = 'Unexpected Get-BitLockerVolume failure. On the device run "manage-bde -status", check Event Viewer > Applications and Services Logs > Microsoft > Windows > BitLocker-API, and send this BitLockerError text to the script owner.'
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$isElevated = ([Security.Principal.WindowsPrincipal]$identity).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

function Get-CodedName($table, $value) {
    if ($null -eq $value) { return $null }
    $name = $table[[int]$value]
    if ($name) { $name } else { 'Unknown' }
}

function Format-Coded($table, $value) {
    if ($null -eq $value) { return $null }
    '{0} ({1})' -f (Get-CodedName $table $value), $value
}

function Get-BitLockerFailure($errorRecord) {
    $exception = $errorRecord.Exception
    $native = if ($exception.PSObject.Properties['NativeErrorCode']) { [string]$exception.NativeErrorCode }
    $text = "$native $($exception.Message)"
    $status = if ($exception -is [Management.Automation.CommandNotFoundException]) { 'ModuleMissing' }
    elseif ($text -match 'AccessDenied|Access denied|UnauthorizedAccess') { 'AccessDenied' }
    else { 'ProviderError' }
    @{
        Status   = $status
        Detail   = '{0}: {1} [NativeErrorCode={2}, HResult=0x{3:X8}]' -f $exception.GetType().Name, $exception.Message.Trim(), $native, $exception.HResult
        NextStep = $NextSteps[$status]
    }
}

function Get-TpmSummary {
    # Just enough to tell "BitLocker is off" from "no usable TPM"; Get-TpmCapabilities has the detail
    $summary = @{ TpmEnabled = $false; TpmReady = $false; Warning = $null }
    try {
        $tpm = Get-Tpm
        if (-not $tpm) { $summary.Warning = 'Get-Tpm returned nothing (needs an elevated run)' }
        elseif (-not $tpm.TpmPresent) { $summary.Warning = 'No TPM found' }
        else {
            $summary.TpmEnabled = [bool]$tpm.TpmEnabled
            $summary.TpmReady = [bool]$tpm.TpmReady
        }
    } catch {
        $summary.Warning = "TPM state unreadable ($($_.Exception.Message.Trim()))"
    }
    $summary
}

$tpmSummary = Get-TpmSummary

function Get-VolumeRow([System.Collections.IDictionary]$fields) {
    $row = [ordered]@{
        BitLockerQueryStatus = $null
        MountPoint           = $null
        IsOsVolume           = $null
        ProtectionStatus     = $null
        ConversionStatus     = $null
        PercentEncrypted     = $null
        EncryptionMethod     = $null
        LockStatus           = $null
        KeyProtectors        = $null
        TpmEnabled           = $tpmSummary.TpmEnabled
        TpmReady             = $tpmSummary.TpmReady
        Assessment           = $null
        BitLockerError       = $null
        BitLockerNextStep    = $null
        BitLockerWarnings    = $null
        ScannerRunAs         = $identity.Name
        ScannerElevated      = $isElevated
    }
    foreach ($key in $fields.Keys) { $row[$key] = $fields[$key] }
    if ($tpmSummary.Warning) { $row.BitLockerWarnings = ($row.BitLockerWarnings, $tpmSummary.Warning | Where-Object { $_ }) -join '; ' }
    [pscustomobject]$row
}

function Get-VolumeAssessment($isOs, $protName, $convName, $hasTpmProtector) {
    $kind = if ($isOs) { 'OS volume' } else { 'Data volume' }
    if ($null -eq $protName) { return "$kind protection status could not be read (see BitLockerWarnings)" }
    if ($protName -eq 'On') {
        if (-not $isOs) { return 'Data volume protected' }
        if ($hasTpmProtector) { return 'OS volume protected with a TPM protector' }
        return 'OS volume protected WITHOUT a TPM protector'
    }
    if ($protName -eq 'Unknown') { return "$kind protection status is unknown (the volume may be locked)" }
    if ($convName -eq 'FullyEncrypted') { return "$kind is encrypted but protection is OFF (suspended; key is stored in the clear)" }
    if ($convName -in 'EncryptionInProgress', 'EncryptionPaused') { return "$kind encryption $convName; protection not yet on" }
    "$kind not protected"
}

function Get-BitLockerRow {
    try {
        $volumes = @(Get-BitLockerVolume)
    } catch {
        $failure = Get-BitLockerFailure $_
        Get-VolumeRow @{
            BitLockerQueryStatus = $failure.Status
            Assessment           = 'BitLocker status unavailable (see BitLockerError)'
            BitLockerError       = $failure.Detail
            BitLockerNextStep    = $failure.NextStep
        }
        return
    }
    if (-not $volumes) {
        Get-VolumeRow @{
            BitLockerQueryStatus = 'NoVolumes'
            Assessment           = 'No encryptable volumes found'
            BitLockerError       = 'Get-BitLockerVolume returned no volumes.'
            BitLockerNextStep    = 'Check that the device has fixed disks. If it should, run "manage-bde -status" on the device and send the result to the script owner.'
        }
        return
    }

    foreach ($volume in $volumes) {
        $warnings = [System.Collections.Generic.List[string]]::new()
        $mount = [string]$volume.MountPoint
        $isOs = [bool]($mount -and $mount -ieq $env:SystemDrive)

        $types = @($volume.KeyProtector | ForEach-Object { [int]$_.KeyProtectorType })
        $isLocked = ([int]$volume.LockStatus -eq 1)
        if ($isLocked -and -not $types) { $warnings.Add('Volume is locked; key protectors could not be read.') }

        $protName = Get-CodedName $ProtectionNames $volume.ProtectionStatus
        $convName = Get-CodedName $ConversionNames $volume.VolumeStatus
        $hasTpmProtector = [bool]($types | Where-Object { $_ -in $TpmProtectorTypes })

        Get-VolumeRow @{
            BitLockerQueryStatus = 'Ok'
            MountPoint           = $mount
            IsOsVolume           = $isOs
            ProtectionStatus     = Format-Coded $ProtectionNames $volume.ProtectionStatus
            ConversionStatus     = Format-Coded $ConversionNames $volume.VolumeStatus
            PercentEncrypted     = $volume.EncryptionPercentage
            EncryptionMethod     = Format-Coded $MethodNames $volume.EncryptionMethod
            LockStatus           = Format-Coded $LockNames $volume.LockStatus
            KeyProtectors        = if ($isLocked -and -not $types) { $null } else { ($types | ForEach-Object { Format-Coded $ProtectorNames $_ }) -join ', ' }
            Assessment           = Get-VolumeAssessment $isOs $protName $convName $hasTpmProtector
            BitLockerWarnings    = if ($warnings.Count) { $warnings -join '; ' } else { $null }
        }
    }
}

try {
    Get-BitLockerRow
} catch {
    # Always emit a row so the device shows up with a diagnosis
    Get-VolumeRow @{
        BitLockerQueryStatus = 'ScriptError'
        Assessment           = 'BitLocker status unavailable (see BitLockerError)'
        BitLockerError       = '{0}: {1} (line {2})' -f $_.Exception.GetType().Name, $_.Exception.Message.Trim(), $_.InvocationInfo.ScriptLineNumber
        BitLockerNextStep    = 'Unexpected scanner failure. Send this BitLockerError text to the script owner.'
    }
}
