<#
.SYNOPSIS
    PDQ Connect package - make a present, enabled TPM ready (a BitLocker prerequisite).

.DESCRIPTION
    If Get-Tpm shows the TPM present but not ready, runs Enable-TpmAutoProvisioning and
    Initialize-Tpm. Already ready: 'NothingToDo'. Missing or disabled in firmware: 'Failed'
    (needs BIOS/UEFI or a hypervisor vTPM). 'RebootRequired' is not a failure; re-run after the restart.
    One row per action plus a final 'TpmState' row; exits 1 on any failure.
    Run as SYSTEM / local administrator. Windows PowerShell 5.1.

.PARAMETER ClearIfNeeded
    DESTRUCTIVE, default $false. Runs Clear-Tpm, then Initialize-Tpm, when the TPM is owned and still
    not ready. Destroys all TPM keys (BitLocker, Hello, certificates). Refused, with no override, if
    any BitLocker volume is protected or has a TPM protector, or BitLocker state can't be read.

.PARAMETER DryRun
    $true = report only, change nothing.
#>
[CmdletBinding()]
param(
    [bool]$ClearIfNeeded = $false,
    [bool]$DryRun = $false
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]
$restart = $acted = $false

function Add-Result([string]$Action, [string]$Status, [string]$Detail) {
    $script:results.Add([pscustomobject][ordered]@{
            ComputerName = $env:COMPUTERNAME
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

function Invoke-TpmStep([string]$Action, [scriptblock]$Command) {
    try {
        $actionResult = & $Command
        $need = [bool]($actionResult.RestartRequired -or $actionResult.ShutdownRequired)
        if ($need) { $script:restart = $true }
        $status = if ($need) { 'RebootRequired' } else { 'Done' }
        Add-Result $Action $status "RestartRequired=$($actionResult.RestartRequired); ShutdownRequired=$($actionResult.ShutdownRequired); TpmReady=$($actionResult.TpmReady)"
    } catch {
        Add-Result $Action 'Failed' "$Action failed: $($_.Exception.Message)"
    }
}

# ---- Pre-flight ----
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Add-Result 'Preflight' 'Failed' 'Must run elevated (administrator/SYSTEM).'; Complete-Run }

if (-not (Get-Command Get-Tpm -ErrorAction SilentlyContinue)) {
    Add-Result 'Preflight' 'Failed' 'TrustedPlatformModule PowerShell module not available (unsupported edition).'
    Complete-Run
}

try { $tpm = Get-Tpm -ErrorAction Stop }
catch { Add-Result 'Preflight' 'Failed' "Get-Tpm failed: $($_.Exception.Message)"; Complete-Run }

$dryRunLabel = if ($DryRun) { 'DRY RUN - ' } else { '' }

# ---- Decide ----
if (-not $tpm.TpmPresent) {
    Add-Result 'Preflight' 'Failed' 'No TPM detected. It cannot be enabled from the OS: enable it in BIOS/UEFI (Intel PTT / AMD fTPM / discrete TPM) or add a vTPM to the VM in the hypervisor.'
} elseif (-not $tpm.TpmEnabled) {
    Add-Result 'Preflight' 'Failed' 'TPM is present but disabled in firmware. It cannot be enabled from the OS: enable it in BIOS/UEFI.'
} elseif ($tpm.TpmReady) {
    Add-Result 'TpmReady' 'NothingToDo' 'TPM is already ready.'
} elseif ($DryRun) {
    Add-Result 'AutoProvisioning' 'DryRun' "${dryRunLabel}Would run Enable-TpmAutoProvisioning."
    Add-Result 'Initialize-Tpm' 'DryRun' "${dryRunLabel}Would run Initialize-Tpm (Owned=$($tpm.TpmOwned))."
    if ($ClearIfNeeded) { Add-Result 'Clear-Tpm' 'DryRun' "${dryRunLabel}Would run Clear-Tpm only if the TPM stays owned and not ready and no BitLocker volume is protected." }
} else {
    $acted = $true
    try {
        $null = Enable-TpmAutoProvisioning -ErrorAction Stop
        Add-Result 'AutoProvisioning' 'Enabled' 'Enable-TpmAutoProvisioning succeeded.'
    } catch { Add-Result 'AutoProvisioning' 'Failed' "Enable-TpmAutoProvisioning failed: $($_.Exception.Message)" }

    Invoke-TpmStep 'Initialize-Tpm' { Initialize-Tpm -ErrorAction Stop }
    $tpm = Get-Tpm

    if (-not $tpm.TpmReady -and -not $restart -and $tpm.TpmOwned -and $ClearIfNeeded) {
        try {
            $bitLockerVolumes = @(Get-BitLockerVolume -ErrorAction Stop |
                    Where-Object { [string]$_.ProtectionStatus -eq 'On' -or @($_.KeyProtector.KeyProtectorType) -match 'Tpm' })
        } catch { $bitLockerVolumes = $null }
        if ($null -eq $bitLockerVolumes) {
            Add-Result 'Clear-Tpm' 'Skipped' 'Refused: BitLocker state could not be read, so clearing is not known to be safe.'
        } elseif ($bitLockerVolumes.Count -gt 0) {
            Add-Result 'Clear-Tpm' 'Skipped' "Refused: BitLocker volume(s) [$(($bitLockerVolumes.MountPoint) -join ', ')] depend on the TPM; clearing would destroy their keys. Decrypt or remove TPM protectors first."
        } else {
            Invoke-TpmStep 'Clear-Tpm' { Clear-Tpm -ErrorAction Stop }
            if (-not $restart) { Invoke-TpmStep 'Initialize-Tpm' { Initialize-Tpm -ErrorAction Stop } }
        }
    }
}

# ---- Final state ----
try {
    $tpm = Get-Tpm -ErrorAction Stop
    $restart = $restart -or [bool]$tpm.RestartPending
    if ($tpm.TpmPresent -and $tpm.TpmEnabled -and $acted) {
        if ($tpm.TpmReady) { Add-Result 'TpmReady' 'Ready' 'TPM is ready.' }
        elseif ($restart) { Add-Result 'TpmReady' 'RebootRequired' 'Restart (or shutdown) the device to finish provisioning, then re-run to confirm.' }
        else {
            $hint = if ($tpm.LockedOut) { 'TPM is locked out; wait for the lockout to expire or reset it in firmware.' }
            elseif ($tpm.TpmOwned -and -not $ClearIfNeeded) { 'TPM has an unknown owner; if no BitLocker/Hello keys matter, re-run with -ClearIfNeeded $true.' }
            else { 'Check the TPM state above.' }
            Add-Result 'TpmReady' 'Failed' "Still not ready (Owned=$($tpm.TpmOwned); LockedOut=$($tpm.LockedOut)). $hint"
        }
    }
    Add-Result 'TpmState' 'Info' ("Present=$($tpm.TpmPresent); Enabled=$($tpm.TpmEnabled); Ready=$($tpm.TpmReady); " +
        "Owned=$($tpm.TpmOwned); RestartNeeded=$restart")
} catch {
    Add-Result 'TpmState' 'Failed' "Could not read final state: $($_.Exception.Message)"
}

Complete-Run
