<#
.SYNOPSIS
    PDQ Connect package - undo BitLocker policy (registry) set by Set-BitlockerPolicy.ps1.

.DESCRIPTION
    Restores each value to what it was before Set-BitlockerPolicy.ps1 changed it, using
    HKLM:\SOFTWARE\PDQ\BitLockerPolicyBackup; a value that wasn't set originally is removed. Values not
    in the backup are left alone. Restored entries leave the backup, and the backup and
    HKLM:\SOFTWARE\Policies\Microsoft\FVE keys are deleted once empty.
    -All $true instead removes every FVE value regardless of the backup (the backup stays).

    Only policy is touched; encryption, protectors, and recovery keys stay. A GPO or MDM policy
    re-applies its own values on its next refresh.
    One row per value plus a final 'PolicyState' row; exits 1 on any failure.
    Run as SYSTEM / local administrator. Windows PowerShell 5.1.

.PARAMETER Name
    Comma separated value names to act on. Default: everything in the backup (with -All, every FVE value).

.PARAMETER All
    $true = remove values (or those in -Name) instead of restoring from the backup.

.PARAMETER DryRun
    $true = report only, change nothing.

.PARAMETER KeyPath / BackupPath
    Policy and backup keys. Defaults are the real ones; only override for testing.
#>
[CmdletBinding()]
param(
    [string[]]$Name,
    [bool]$All = $false,
    [bool]$DryRun = $false,
    [string]$KeyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\FVE',
    [string]$BackupPath = 'HKLM:\SOFTWARE\PDQ\BitLockerPolicyBackup'
)

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

$Name = @($Name | ForEach-Object { $_ -split '[,;\s]+' } | Where-Object { $_ })

# ---- Pre-flight ----
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($KeyPath -like 'HKLM:*' -and -not $isAdmin) { Add-Result 'Preflight' 'Failed' 'Must run elevated (administrator/SYSTEM).'; Complete-Run }

$dryRunLabel = if ($DryRun) { 'DRY RUN - ' } else { '' }
$key = Get-Item -Path $KeyPath -ErrorAction SilentlyContinue
$backupKey = Get-Item -Path $BackupPath -ErrorAction SilentlyContinue
$keyLeft = New-Object System.Collections.Generic.List[string]   # FVE values remaining afterwards
if ($key) { $key.GetValueNames() | Where-Object { $_ } | ForEach-Object { $keyLeft.Add($_) } }
$backupLeft = New-Object System.Collections.Generic.List[string]    # backup entries remaining afterwards
if ($backupKey) { $backupKey.GetValueNames() | Where-Object { $_ } | ForEach-Object { $backupLeft.Add($_) } }

if ($All) {
    # ---- Remove values regardless of backup ----
    if (-not $key) { Add-Result 'Key' 'NotPresent' $KeyPath }
    $have = @($keyLeft)
    $targets = if ($Name.Count) { @($have | Where-Object { $_ -in $Name }) } else { $have }
    foreach ($valueName in @($Name | Where-Object { $_ -notin $have })) { Add-Result $valueName 'NotPresent' 'Value not set.' }
    foreach ($valueName in $targets) {
        $previousValue = "$($key.GetValueKind($valueName)) $($key.GetValue($valueName))"
        if ($DryRun) { Add-Result $valueName 'DryRun' "${dryRunLabel}Would remove (was $previousValue)."; [void]$keyLeft.Remove($valueName); continue }
        try {
            Remove-ItemProperty -Path $KeyPath -Name $valueName
            Add-Result $valueName 'Removed' "was $previousValue"; [void]$keyLeft.Remove($valueName)
        } catch { Add-Result $valueName 'Failed' $_.Exception.Message }
    }
} elseif (-not $backupKey) {
    Add-Result 'Backup' 'NotPresent' "No backup at $BackupPath, so nothing was restored. Use -All `$true to remove every value instead."
} else {
    # ---- Restore originals saved by Set-BitlockerPolicy.ps1 ----
    $saved = @($backupLeft | Where-Object { -not $Name.Count -or $_ -in $Name })
    foreach ($valueName in @($Name | Where-Object { $_ -notin $backupLeft })) { Add-Result $valueName 'NotPresent' 'No saved original for this value.' }
    foreach ($valueName in $saved) {
        $kind, $valueData = ([string]$backupKey.GetValue($valueName)) -split '\|', 2
        $target = if ($kind -eq 'NotSet') { 'remove value (was not set originally)' } else { "$kind $valueData" }
        if ($DryRun) {
            Add-Result $valueName 'DryRun' "${dryRunLabel}Would restore: $target."
            if ($kind -eq 'NotSet') { [void]$keyLeft.Remove($valueName) } elseif ($valueName -notin $keyLeft) { $keyLeft.Add($valueName) }
            [void]$backupLeft.Remove($valueName)
            continue
        }
        try {
            if ($kind -eq 'NotSet') {
                if ($valueName -in $keyLeft) { Remove-ItemProperty -Path $KeyPath -Name $valueName }
                [void]$keyLeft.Remove($valueName)
            } else {
                if (-not (Test-Path $KeyPath)) { $null = New-Item -Path $KeyPath -Force }
                Set-ItemProperty -Path $KeyPath -Name $valueName -Value $(if ($kind -eq 'DWord') { [int]$valueData } else { $valueData }) -Type $kind
                if ($valueName -notin $keyLeft) { $keyLeft.Add($valueName) }
            }
            Remove-ItemProperty -Path $BackupPath -Name $valueName
            [void]$backupLeft.Remove($valueName)
            Add-Result $valueName 'Restored' $target
        } catch { Add-Result $valueName 'Failed' $_.Exception.Message }
    }
}

# ---- Remove the keys if nothing is left ----
$failed = @($results | Where-Object { $_.Status -eq 'Failed' }).Count
$subKeys = if ($key) { $key.SubKeyCount } else { 0 }
foreach ($keyEntry in @(
        @{ Path = $KeyPath; Exists = [bool]$key; Left = $keyLeft; Subs = $subKeys },
        @{ Path = $BackupPath; Exists = [bool]$backupKey; Left = $backupLeft; Subs = 0 })) {
    if (-not $keyEntry.Exists -or $keyEntry.Left.Count -gt 0 -or $keyEntry.Subs -gt 0 -or $failed -gt 0) { continue }
    if ($keyEntry.Path -eq $BackupPath -and $All) { continue }
    if ($DryRun) { Add-Result 'Key' 'DryRun' "${dryRunLabel}Would remove $($keyEntry.Path)." }
    else {
        try { Remove-Item -Path $keyEntry.Path; Add-Result 'Key' 'Removed' $keyEntry.Path }
        catch { Add-Result 'Key' 'Failed' $_.Exception.Message }
    }
}

# ---- Final state ----
$count = { param($statusName) @($results | Where-Object { $_.Status -eq $statusName }).Count }
Add-Result 'PolicyState' 'Info' ("Restored=$(& $count 'Restored'); Removed=$(& $count 'Removed'); NotPresent=$(& $count 'NotPresent'); " +
    "Failed=$(& $count 'Failed'); DryRun=$(& $count 'DryRun'); Key=$KeyPath")

Complete-Run
