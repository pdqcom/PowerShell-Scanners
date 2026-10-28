# Bitlocker Mgmt

## Instructions

[How to use this repository](../../README.md)

Full usage guide, including how to build the PDQ Connect reports: [INSTRUCTIONS.md](INSTRUCTIONS.md)

## Description

Scanners and packages to inspect and manage TPM and BitLocker on Windows devices.

* `scanners/` reports TPM capabilities, BitLocker volume status and key protectors (including recovery passwords).
* `packages/` makes the TPM ready, sets and removes BitLocker policy, adds and removes key protectors, and decrypts a drive.

| Script | Folder | What it does |
|---|---|---|
| `Get-TpmCapabilities.ps1` | `scanners` | TPM presence, state, firmware type, Secure Boot, virtual machine |
| `Get-BitLockerStatus.ps1` | `scanners` | One row per volume: encryption and protection state, protector types |
| `Get-BitLockerProtectors.ps1` | `scanners` | One row per key protector, with recovery password and backup source |
| `Set-TpmReady.ps1` | `packages` | Enable auto-provisioning and initialize the TPM |
| `Set-BitlockerPolicy.ps1` | `packages` | Write BitLocker (FVE) policy to the registry, with a backup of the originals |
| `Remove-BitlockerPolicy.ps1` | `packages` | Restore or remove that policy |
| `Enable-BitLockerProtectors.ps1` | `packages` | Add protectors, start encryption, optionally escrow to AD / Entra ID |
| `Remove-BitLockerProtectors.ps1` | `packages` | Remove key protectors |
| `Disable-BitLocker.ps1` | `packages` | Decrypt a drive |

## Requirements

* Windows PowerShell 5.1, run as SYSTEM or a local administrator
* The BitLocker PowerShell module (not available on Windows Home editions)
* The TrustedPlatformModule PowerShell module (`Get-Tpm`)

`Get-BitLockerProtectors.ps1` writes recovery passwords into the scan results. Restrict who can view that data in PDQ Connect.

## Compatibility

* **PDQ Inventory**: Not tested. A `Scan Profile` for each scanner is in `scanners/` (`Get-*.xml`).
* **PDQ Connect**: Yes

## Parameters

The scanners take no parameters. Every package takes `-DryRun $true` to report without changing anything; the other parameters are described per package in [INSTRUCTIONS.md](INSTRUCTIONS.md#packages).

## Author

Jeff Pinkston
