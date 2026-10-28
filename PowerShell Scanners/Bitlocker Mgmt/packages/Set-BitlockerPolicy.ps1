<#
.SYNOPSIS
    PDQ Connect package - configure BitLocker policy (registry) on this device.

.DESCRIPTION
    Writes the $Policy table below to HKLM:\SOFTWARE\Policies\Microsoft\FVE, where Group Policy writes
    it. Edit the table to change the policy; a $null value skips that entry. Does not encrypt or add
    protectors (see Enable-BitLockerProtectors.ps1). Uses the registry because the MDM bridge needs
    MDM enrollment.

    Only changed values are written. Each original is first saved to
    HKLM:\SOFTWARE\PDQ\BitLockerPolicyBackup (first original wins) for Remove-BitlockerPolicy.ps1;
    a value is left alone if its backup can't be written.

    Refuses to run (exit 1, nothing written) if the policy key holds a value this script did not
    back up: it came from GPO, MDM or someone else, and would be overwritten or fight this script.
    Only policy already applied is detected. To take over, clear it first with
    Remove-BitlockerPolicy.ps1 -All $true.
    Policy applies when BitLocker next acts; it does not re-encrypt existing volumes.
    One row per setting plus a final 'PolicyState' row; exits 1 on any failure.
    Run as SYSTEM / local administrator. Windows PowerShell 5.1.

.PARAMETER DryRun
    $true = report only, change nothing.

.PARAMETER KeyPath / BackupPath
    Policy and backup keys. Defaults are the real ones; only override for testing.
#>
[CmdletBinding()]
param(
    [bool]$DryRun = $false,
    [string]$KeyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\FVE',
    [string]$BackupPath = 'HKLM:\SOFTWARE\PDQ\BitLockerPolicyBackup'
)

# ---- Name = Type, Value ($null = skip). OS = operating system drive, FDV = fixed data, RDV = removable data ----
$Policy = [ordered]@{
    # Cipher: 3=AES-CBC128, 4=AES-CBC256, 6=XTS-AES128, 7=XTS-AES256 (all four valid for OS, FDV and RDV)
    EncryptionMethodWithXtsOs     = 'DWord', 7
    EncryptionMethodWithXtsFdv    = 'DWord', 7
    EncryptionMethodWithXtsRdv    = 'DWord', 7

    # Encryption type: 0=let the user choose, 1=full, 2=used space only
    OSEncryptionType              = 'DWord', 1
    FDVEncryptionType             = 'DWord', 1
    RDVEncryptionType             = 'DWord', 1

    # OS startup authentication. 0=disallow, 1=require, 2=allow
    UseAdvancedStartup            = 'DWord', 1  # 1=configure the options below
    EnableBDEWithNoTPM            = 'DWord', 0  # 1=allow without a TPM
    UseTPM                        = 'DWord', 2  # TPM only
    UseTPMPIN                     = 'DWord', 2  # TPM + PIN
    UseTPMKey                     = 'DWord', $null  # TPM + startup key
    UseTPMKeyPIN                  = 'DWord', $null  # TPM + startup key + PIN
    MinimumPIN                    = 'DWord', $null  # minimum PIN length, 4-20

    # OS recovery
    OSRecovery                    = 'DWord', 1  # 1=configure the options below
    OSManageDRA                   = 'DWord', 0  # 1=allow data recovery agent
    OSRecoveryPassword            = 'DWord', 2  # 0=disallow, 1=require, 2=allow
    OSRecoveryKey                 = 'DWord', 2  # 0=disallow, 1=require, 2=allow
    OSHideRecoveryPage            = 'DWord', 0  # 1=hide recovery options in the wizard
    OSActiveDirectoryBackup       = 'DWord', 1  # 1=back up to AD DS
    OSActiveDirectoryInfoToStore  = 'DWord', 1  # 1=password and key package, 2=password only
    OSRequireActiveDirectoryBackup = 'DWord', 0 # 1=block enabling unless AD backup succeeds (fails off-domain)

    # FDV recovery (same values as OS)
    FDVRecovery                   = 'DWord', 1
    FDVManageDRA                  = 'DWord', 0
    FDVRecoveryPassword           = 'DWord', 2
    FDVRecoveryKey                = 'DWord', 2
    FDVHideRecoveryPage           = 'DWord', 0
    FDVActiveDirectoryBackup      = 'DWord', 1
    FDVActiveDirectoryInfoToStore = 'DWord', 1
    FDVRequireActiveDirectoryBackup = 'DWord', 0

    # RDV recovery (same values as OS)
    RDVRecovery                   = 'DWord', 1
    RDVManageDRA                  = 'DWord', 0
    RDVRecoveryPassword           = 'DWord', 2
    RDVRecoveryKey                = 'DWord', 2
    RDVHideRecoveryPage           = 'DWord', 0
    RDVActiveDirectoryBackup      = 'DWord', 1
    RDVActiveDirectoryInfoToStore = 'DWord', 1
    RDVRequireActiveDirectoryBackup = 'DWord', 0

    # Deny write to drives not protected by BitLocker. 0=no, 1=yes
    FDVDenyWriteAccess            = 'DWord', $null
    RDVDenyWriteAccess            = 'DWord', $null
}

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]

function Add-Result([string]$Setting, [string]$Status, [string]$Detail) {
    $script:results.Add([pscustomobject][ordered]@{
            ComputerName = $env:COMPUTERNAME
            Setting      = $Setting
            Status       = $Status
            Detail       = $Detail
        })
}

function Complete-Run {
    $results | Format-Table -AutoSize -Wrap | Out-String -Width 4096 | Write-Output
    if (@($results | Where-Object { $_.Status -eq 'Failed' }).Count -gt 0) { exit 1 }
    exit 0
}

# ---- Pre-flight ----
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($KeyPath -like 'HKLM:*' -and -not $isAdmin) { Add-Result 'Preflight' 'Failed' 'Must run elevated (administrator/SYSTEM).'; Complete-Run }

# Every value this script writes is backed up first, so a value with no backup entry is not ours
$policyKey = Get-Item -Path $KeyPath -ErrorAction SilentlyContinue
$backupKey = Get-Item -Path $BackupPath -ErrorAction SilentlyContinue
$owned = if ($backupKey) { @($backupKey.GetValueNames()) } else { @() }
$foreign = if ($policyKey) { @($policyKey.GetValueNames() | Where-Object { $_ -and $_ -notin $owned }) } else { @() }
if ($foreign.Count -gt 0) {
    Add-Result 'ManagedPolicy' 'Failed' "$KeyPath has $($foreign.Count) value(s) set outside this script ($($foreign -join ', ')). Likely GPO/MDM; nothing changed."
    Complete-Run
}

$dryRunLabel = if ($DryRun) { 'DRY RUN - ' } else { '' }
if (-not (Test-Path $KeyPath)) {
    if ($DryRun) { Add-Result 'Key' 'DryRun' "${dryRunLabel}Would create $KeyPath." }
    else {
        try { $null = New-Item -Path $KeyPath -Force; Add-Result 'Key' 'Created' $KeyPath }
        catch { Add-Result 'Key' 'Failed' "Could not create ${KeyPath}: $($_.Exception.Message)"; Complete-Run }
    }
}

# ---- Apply ----
$key = Get-Item -Path $KeyPath -ErrorAction SilentlyContinue
foreach ($name in $Policy.Keys) {
    $type, $want = $Policy[$name]
    if ($null -eq $want) { Add-Result $name 'Skipped' 'Not configured (value is $null).'; continue }

    $have = if ($key) { $key.GetValue($name, $null) }
    $kind = if ($null -ne $have) { [string]$key.GetValueKind($name) }
    if ($kind -eq $type -and "$have" -ceq "$want") { Add-Result $name 'AlreadyCorrect' "$type $want"; continue }

    $from = if ($null -eq $have) { 'not set' } else { "$kind $have" }
    if ($DryRun) { Add-Result $name 'DryRun' "${dryRunLabel}Would set $type $want (was $from)."; continue }
    try {
        $backupKeyItem = Get-Item -Path $BackupPath -ErrorAction SilentlyContinue
        if (-not $backupKeyItem) { $backupKeyItem = New-Item -Path $BackupPath -Force }
        if ($name -notin $backupKeyItem.GetValueNames()) {
            $null = New-ItemProperty -Path $BackupPath -Name $name -PropertyType String -Value $(if ($null -eq $have) { 'NotSet' } else { "$kind|$have" })
        }
        Set-ItemProperty -Path $KeyPath -Name $name -Value $want -Type $type
        Add-Result $name 'Set' "$type $want (was $from)"
    } catch { Add-Result $name 'Failed' $_.Exception.Message }
}

# ---- Final state ----
$count = { param($statusName) @($results | Where-Object { $_.Status -eq $statusName }).Count }
Add-Result 'PolicyState' 'Info' ("Set=$(& $count 'Set'); AlreadyCorrect=$(& $count 'AlreadyCorrect'); " +
    "Failed=$(& $count 'Failed'); DryRun=$(& $count 'DryRun'); Skipped=$(& $count 'Skipped'); Key=$KeyPath")

Complete-Run
