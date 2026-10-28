<#
.SYNOPSIS
    PDQ Connect scanner: BitLocker key protectors and recovery passwords.

.DESCRIPTION
    Emits one object per key protector per volume. A volume with no protectors gets one row with
    KeyProtectorType = 'None'; when Get-BitLockerVolume can't be run, one row carries only the
    status. Needs the BitLocker PowerShell module. Coded values are shown as "Name (value)". Fields that can't be read are $null, and
    Get-BitLockerStatus.ps1 reports the reason for the same device.

    RecoveryPassword is read locally, which needs the scanner elevated and the volume unlocked
    (RecoverySource is Local or NotFound). It is written to the scan output, so restrict who can
    view it in PDQ Connect.

    RecoveryBackup is the last successful backup Windows logged for that protector: Entra ID
    (event 845) or Active Directory (784, 783) with the UTC time, or "Deleted from Entra ID"
    (4123). The event log rolls over, so "No backup event found" doesn't prove the key isn't
    escrowed. Nothing is queried from AD or Entra.

    BitLockerQueryStatus is Ok, NoVolumes, ModuleMissing, AccessDenied, ProviderError or
    ScriptError.

    Run as SYSTEM or a local administrator. Compatible with Windows PowerShell 5.1.
#>

$ErrorActionPreference = 'Stop'

$ProtectorNames = @{ 0 = 'Unknown'; 1 = 'Tpm'; 2 = 'ExternalKey'; 3 = 'RecoveryPassword'; 4 = 'TpmPin'
    5 = 'TpmStartupKey'; 6 = 'TpmPinStartupKey'; 7 = 'PublicKey'; 8 = 'Password'
    9 = 'TpmCertificate'; 10 = 'CryptoApiNextGeneration'
}
$RecoveryPasswordType = 3

# BitLocker Management events, and where each one keeps the protector GUID in its properties
$BackupEventLog = 'Microsoft-Windows-BitLocker/BitLocker Management'
$BackupEventGuidIndex = @{ 845 = 1; 4123 = 1; 784 = 3; 783 = 3 }

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$isElevated = ([Security.Principal.WindowsPrincipal]$identity).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

function Format-ProtectorType($value) {
    $name = if ($ProtectorNames.ContainsKey([int]$value)) { $ProtectorNames[[int]$value] } else { 'Unknown' }
    '{0} ({1})' -f $name, $value
}

function ConvertTo-GuidKey($guid) {
    ([string]$guid).Trim('{', '}').ToLowerInvariant()
}

function Get-FailureStatus($errorRecord) {
    $exception = $errorRecord.Exception
    $native = if ($exception.PSObject.Properties['NativeErrorCode']) { [string]$exception.NativeErrorCode }
    $text = "$native $($exception.Message)"
    if ($exception -is [Management.Automation.CommandNotFoundException]) { return 'ModuleMissing' }
    if ($text -match 'AccessDenied|Access denied|UnauthorizedAccess') { return 'AccessDenied' }
    'ProviderError'
}

function Get-ProtectorRow([System.Collections.IDictionary]$fields) {
    $row = [ordered]@{
        BitLockerQueryStatus = $null
        MountPoint           = $null
        KeyProtectorId       = $null
        KeyProtectorType     = $null
        RecoveryPassword     = $null
        RecoverySource       = $null
        RecoveryBackup       = $null
        ScannerRunAs         = $identity.Name
        ScannerElevated      = $isElevated
    }
    foreach ($key in $fields.Keys) { $row[$key] = $fields[$key] }
    [pscustomobject]$row
}

function Get-BackupEvent {
    # Returns $null when the log can't be read, and an empty array when it has no matching events
    try {
        $found = @(Get-WinEvent -FilterHashtable @{ LogName = $BackupEventLog; Id = [int[]]$BackupEventGuidIndex.Keys })
    } catch {
        if ($_.FullyQualifiedErrorId -notlike 'NoMatchingEventsFound*') { return $null }
        $found = @()
    }
    , @($found | ForEach-Object {
            [pscustomobject]@{
                Id        = $_.Id
                Time      = $_.TimeCreated.ToUniversalTime()
                Protector = ConvertTo-GuidKey $_.Properties[$BackupEventGuidIndex[[int]$_.Id]].Value
            }
        })
}

function Format-BackupSource([string]$label, $backupEvent) {
    '{0} (event log, {1:yyyy-MM-dd HH:mm} UTC)' -f $label, $backupEvent.Time
}

function Get-RecoveryBackup($events, $protectorId) {
    if ($null -eq $events) { return $null }
    $key = ConvertTo-GuidKey $protectorId
    $mine = @($events | Where-Object { $_.Protector -eq $key } | Sort-Object Time -Descending)
    $entraEvent = $mine | Where-Object { $_.Id -in 845, 4123 } | Select-Object -First 1
    $adEvent = $mine | Where-Object { $_.Id -in 784, 783 } | Select-Object -First 1

    $found = New-Object System.Collections.Generic.List[string]
    if ($entraEvent) { $found.Add((Format-BackupSource $(if ($entraEvent.Id -eq 845) { 'Entra ID' } else { 'Deleted from Entra ID' }) $entraEvent)) }
    if ($adEvent) { $found.Add((Format-BackupSource 'Active Directory' $adEvent)) }
    if ($found.Count -gt 0) { $found -join '; ' } else { 'No backup event found' }
}

function Get-BitLockerProtector {
    try {
        $volumes = @(Get-BitLockerVolume)
    } catch {
        Get-ProtectorRow @{ BitLockerQueryStatus = Get-FailureStatus $_ }
        return
    }
    if (-not $volumes) {
        Get-ProtectorRow @{ BitLockerQueryStatus = 'NoVolumes' }
        return
    }

    $events = Get-BackupEvent

    foreach ($volume in $volumes) {
        $volumeFields = @{
            BitLockerQueryStatus = 'Ok'
            MountPoint           = [string]$volume.MountPoint
        }

        # A locked volume that lists nothing is unreadable, not "no protectors"
        $protectors = @($volume.KeyProtector)
        if (-not $protectors) {
            if ([int]$volume.LockStatus -eq 1) { Get-ProtectorRow $volumeFields }
            else { Get-ProtectorRow ($volumeFields + @{ KeyProtectorType = 'None' }) }
            continue
        }

        foreach ($protector in $protectors) {
            $row = $volumeFields + @{
                KeyProtectorId   = [string]$protector.KeyProtectorId
                KeyProtectorType = Format-ProtectorType ([int]$protector.KeyProtectorType)
            }
            if ([int]$protector.KeyProtectorType -eq $RecoveryPasswordType) {
                $password = [string]$protector.RecoveryPassword
                $row.RecoveryPassword = if ($password) { $password }
                $row.RecoverySource = if ($password) { 'Local' } else { 'NotFound' }
                $row.RecoveryBackup = Get-RecoveryBackup $events $protector.KeyProtectorId
            }
            Get-ProtectorRow $row
        }
    }
}

try {
    Get-BitLockerProtector
} catch {
    Get-ProtectorRow @{ BitLockerQueryStatus = 'ScriptError' }
}
