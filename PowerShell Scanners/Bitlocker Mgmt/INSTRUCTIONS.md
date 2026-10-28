# BitLocker management with PDQ Connect

Purpose: 
- Use BitLocker/TPM scanners and packages to manage TPM and bitlocker policies
- Build reports in PDQ Connect from TPM and Bitlocker data.

| Piece | Location | Purpose |
|---|---|---|
| 3 scanners | `scanners/` | Report TPM, BitLocker volume status and key protectors (with a PDQ Inventory `.xml` scan profile for each) |
| 6 packages | `packages/` | Make the TPM ready, set policy, add/remove protectors, decrypt |

## Contents
1. [Before you start](#before-you-start)
2. [Recommended workflow](#recommended-workflow)
3. [Scanners](#scanners)
4. [Packages](#packages)
5. [Reports in PDQ Connect](#reports-in-pdq-connect)
6. [Troubleshooting](#troubleshooting)
7. [Known limitations](#known-limitations)
8. [Verification status](#verification-status)

---

## Before you start

- **Windows PowerShell 5.1**, run as **SYSTEM or a local administrator**. Every scanner and package checks this. Scanners report `AccessDenied` and packages fail a `Preflight` row when not elevated.
- **BitLocker PowerShell module** (`Get-BitLockerVolume`, `Enable-BitLocker`, ...) must exist. On Windows Server install the feature first: `Install-WindowsFeature BitLocker -IncludeManagementTools`, then reboot. Home editions of Windows do not include BitLocker.
- **TPM module** (`Get-Tpm`) is used by the TPM scanner, the status scanner and the TPM-related packages.
- **Package output convention.** Every package prints a table with one row per action and a final state row, and exits `1` if any row has `Status = Failed`, otherwise `0`. Rows carry `ComputerName` so a deployment's output is readable per device.
- **Dry run first.** Every package has `-DryRun $true`, which reports what it would do and changes nothing. Always dry-run a new policy or removal on one device before deploying widely.

### Sensitive data

- `Get-BitLockerProtectors` writes **recovery passwords into scan results**. Restrict who can view that scanner's data and any report built on it.
- `Enable-BitLockerProtectors` also prints the recovery password in its package output by default (`-ReturnRecoveryPassword`, default `$true`), which stays in the deployment logs. Set it to `$false` if the scanner is your system of record.
- `-Pin` and `-Password` are **plaintext** package parameters, visible to anyone who can view the package and its deployments.

---

## Recommended workflow

1. **Scan** a pilot group with the three scanners. Read `TpmQueryStatus`, `BitLockerQueryStatus` and `Assessment` to see what is blocking each device.
2. **Fix the TPM** where needed: run `Set-TpmReady.ps1`. Devices with no TPM or a TPM disabled in firmware cannot be fixed from the OS (BIOS/UEFI, or add a vTPM in the hypervisor).
3. **Set policy**: run `Set-BitlockerPolicy.ps1` (dry run first). It refuses to run when GPO/MDM already manages FVE policy.
4. **Encrypt**: run `Enable-BitLockerProtectors.ps1`. It adds protectors and starts encryption.
5. **Re-scan** and use the reports below to confirm `ProtectionStatus` is `On` and a recovery password exists (and, if you escrow, that a backup event is logged).
6. **Undo** if needed: `Remove-BitLockerProtectors.ps1` removes individual protectors, `Disable-BitLocker.ps1` decrypts, `Remove-BitlockerPolicy.ps1` restores the original policy values.

Order matters: policy before encryption (so encryption uses the intended cipher and startup options), and a ready TPM before any TPM protector.

---

## Scanners

All three scanners always emit at least one row per device, so a device never silently disappears from a report. A failure shows up in the status column with an explanation and next step. A value that could not be read is `$null`, and Connect exports it as the text `null`.

Coded values are shown as `Name (number)`, for example `Off (0)` or `RecoveryPassword (3)`. Filter on the text, not the number alone.

**Scanner names.** The three scanners are named in Connect as `TPM Capabilities`, `Bitlocker Status` and `Bitlocker Protectors`. Report column headers are suffixed with the scanner name, e.g. `TpmReady (Bitlocker Status)`. Keep these names if you recreate the scanners, or the report columns will differ from the examples below.

**Connect's custom scanner screen**: create a new PowerShell scanner, paste the script, set it to run as **System**, and choose a scan schedule. Create one scanner per script.

### Get-TpmCapabilities.ps1 (`TPM Capabilities`)

One row per device.

| Field | Meaning |
|---|---|
| `TpmQueryStatus` | `Ok`, `NoTpm`, `ModuleMissing`, `AccessDenied`, `ProviderError`, `ScriptError` |
| `TpmPresent`, `TpmEnabled`, `TpmActivated`, `TpmOwned`, `TpmReady` | TPM state from `Get-Tpm`. `TpmReady` is what BitLocker needs. |
| `TpmSpecVersion` | e.g. `2.0` (from `Win32_Tpm`; null with a warning if unreadable) |
| `TpmManufacturer`, `TpmManufacturerVersion` | Vendor name and code, e.g. `VMware (VMW 0x564D5700)` |
| `TpmLockedOut`, `TpmLockoutCount`, `TpmLockoutMax` | Lockout state |
| `TpmRestartRequired` | Restart pending to finish provisioning |
| `TpmAutoProvisioning`, `TpmManagedAuthLevel`, `TpmOwnerClearDisabled` | Provisioning/ownership settings |
| `FirmwareType` | `UEFI (2)` or `Legacy BIOS (1)` |
| `SecureBootEnabled` | Null on legacy BIOS |
| `IsVirtualMachine` | Heuristic on manufacturer/model (VMware, Hyper-V guest, VirtualBox, KVM/QEMU, Xen, ...) |
| `TpmError`, `TpmNextStep`, `TpmWarnings` | Diagnosis for failures and partial reads |
| `ScannerRunAs`, `ScannerElevated` | Account the scanner ran as, and whether it was elevated |

No TPM (`TpmQueryStatus = NoTpm`): all `Tpm*` detail fields are null and `TpmPresent` is `false`. On a VM the fix is a virtual TPM in the hypervisor; on hardware, enable it in BIOS/UEFI.

### Get-BitLockerStatus.ps1 (`Bitlocker Status`)

One row per volume (or one explanatory row if BitLocker cannot be queried).

| Field | Meaning |
|---|---|
| `BitLockerQueryStatus` | `Ok`, `NoVolumes`, `ModuleMissing`, `AccessDenied`, `ProviderError`, `ScriptError` |
| `MountPoint`, `IsOsVolume` | Volume, and whether it is the system drive |
| `ProtectionStatus` | `Off (0)`, `On (1)`, `Unknown (2)` (unknown usually means locked) |
| `ConversionStatus` | `FullyDecrypted`, `FullyEncrypted`, `EncryptionInProgress`, `DecryptionInProgress`, `EncryptionPaused`, `DecryptionPaused` |
| `PercentEncrypted`, `EncryptionMethod` | Progress and cipher (`XtsAes256 (7)`, ...) |
| `LockStatus` | `Unlocked (0)` or `Locked (1)` |
| `KeyProtectors` | Comma list of protector types, e.g. `Tpm (1), RecoveryPassword (3)`. Null if the volume is locked. |
| `TpmEnabled`, `TpmReady` | Repeated on every row. Both `false` if the TPM is missing or unreadable (reason in `BitLockerWarnings`). |
| `Assessment` | One-line verdict, see below |
| `BitLockerError`, `BitLockerNextStep`, `BitLockerWarnings` | Diagnosis |
| `ScannerRunAs`, `ScannerElevated` | As above |

`Assessment` values and what to do:

| Assessment | Meaning / action |
|---|---|
| `OS volume protected with a TPM protector` | Good. |
| `OS volume protected WITHOUT a TPM protector` | Protected by a password/key only. Add a TPM protector if that is not intended. |
| `Data volume protected` | Good. |
| `<OS/Data> volume not protected` | Not encrypted. Candidate for `Enable-BitLockerProtectors`. |
| `... encrypted but protection is OFF (suspended; key is stored in the clear)` | Suspended. Resume protection (not a package in this repo; use `Resume-BitLocker` or `manage-bde -protectors -enable`). |
| `... encryption EncryptionInProgress / EncryptionPaused; protection not yet on` | Wait for completion, or investigate a paused encryption. |
| `... protection status is unknown (the volume may be locked)` | Locked volume; protectors cannot be read. |
| `BitLocker status unavailable (see BitLockerError)` | The query failed; read `BitLockerError` and `BitLockerNextStep`. |

### Get-BitLockerProtectors.ps1 (`Bitlocker Protectors`)

One row per key protector per volume. A volume with no protectors gets one row with `KeyProtectorType = None`.

| Field | Meaning |
|---|---|
| `BitLockerQueryStatus` | Same values as the status scanner |
| `MountPoint`, `KeyProtectorId`, `KeyProtectorType` | Protector identity, e.g. `RecoveryPassword (3)`, `Tpm (1)`, `TpmPin (4)` |
| `RecoveryPassword` | The 48-digit password, **recovery-password protectors only**. Needs an elevated scan and an unlocked volume. |
| `RecoverySource` | `Local` (read from the device) or `NotFound` |
| `RecoveryBackup` | Last backup Windows logged for that protector: `Entra ID (event log, <UTC time>)`, `Active Directory (event log, <UTC time>)`, `Deleted from Entra ID ...`, or `No backup event found` |
| `ScannerRunAs`, `ScannerElevated` | As above |

Notes on `RecoveryBackup`: it is read from the local `Microsoft-Windows-BitLocker/BitLocker Management` event log (events 845, 4123 for Entra; 784, 783 for AD). Nothing is queried from AD or Entra. The log rolls over, so `No backup event found` does not prove a key is *not* escrowed. The AD event IDs come from the provider manifest and have not been confirmed on a domain-joined device.

---

## Packages

All packages: run as SYSTEM/local administrator, Windows PowerShell 5.1, output table plus exit code as described in [Before you start](#before-you-start). Common result statuses: `Failed` (exit 1), `DryRun`, `NothingToDo`/`AlreadyCorrect`/`AlreadyPresent` (idempotent no-ops), `Info` (final state row).

Packages that appear to correspond to scripts already in the tenant (all type `custom`):

| Script | Connect package in the tenant |
|---|---|
| `Set-TpmReady.ps1` | `TPM Enablement` |
| `Set-BitlockerPolicy.ps1` | `Set Bitlocker Policy` |
| `Enable-BitLockerProtectors.ps1` | `Enable Bitlocker Protector` |
| `Remove-BitlockerPolicy.ps1`, `Remove-BitLockerProtectors.ps1`, `Disable-BitLocker.ps1` | Not created yet; create them from the repo scripts |

Confirm the mapping before relying on it; it is inferred from the package names only.

**Creating a package:** create a custom Windows package with a PowerShell step containing the script, running as **System**. Keep the script body unchanged; edit only the parameter values/defaults.

### Set-TpmReady.ps1: make the TPM ready

Prerequisite for any TPM protector. If the TPM is present and enabled but not ready, it runs `Enable-TpmAutoProvisioning` and `Initialize-Tpm`.

| Parameter | Default | Meaning |
|---|---|---|
| `-ClearIfNeeded` | `$false` | **Destructive.** Runs `Clear-Tpm` then `Initialize-Tpm` when the TPM is owned and still not ready. Destroys all TPM keys (BitLocker, Windows Hello, certificates). Refused, with no override, if any BitLocker volume is protected or has a TPM protector, or if BitLocker state cannot be read. |
| `-DryRun` | `$false` | Report only. |

Statuses: `NothingToDo` (already ready), `Enabled`, `Done`, `RebootRequired` (not a failure; restart, then re-run to confirm), `Ready`, `Skipped` (clear refused), `Failed`. Final row `TpmState` shows Present/Enabled/Ready/Owned/RestartNeeded.

It cannot enable a TPM that is missing or disabled in firmware; those end in `Failed` with the BIOS/UEFI or vTPM instruction.

### Set-BitlockerPolicy.ps1: configure policy

Writes the `$Policy` table at the top of the script to `HKLM:\SOFTWARE\Policies\Microsoft\FVE` (where Group Policy writes it). **Edit the table to change the policy**; a `$null` value skips that entry. There are no policy parameters other than `-DryRun`. Out of the box it sets XTS-AES 256 for all three drive types, full-disk encryption type, TPM-only and TPM+PIN startup allowed, recovery password and key allowed, AD backup enabled (not required).

| Parameter | Default | Meaning |
|---|---|---|
| `-DryRun` | `$false` | Report only. |
| `-KeyPath` / `-BackupPath` | the real keys | Only override for testing. |

Behavior to know:

- Each original value is saved to `HKLM:\SOFTWARE\PDQ\BitLockerPolicyBackup` before it is changed (first original wins). A value is left alone if its backup cannot be written.
- **Refuses to run** (`ManagedPolicy` row `Failed`, exit 1, nothing written, also under `-DryRun`) if the FVE key holds a value this script did not back up; that came from GPO, MDM or a person. Only policy that is already applied is detected; MDM policy not yet delivered is not. To take over, run `Remove-BitlockerPolicy.ps1 -All $true` first.
- Policy applies when BitLocker next acts. It does **not** re-encrypt existing volumes.
- Make sure the startup options you need are allowed. An earlier version disallowed TPM-only and made `Enable-BitLockerProtectors` fail with "Group policy does not permit the use of TPM-only at startup" (0x80310066); the current defaults allow it.

Statuses per setting: `Set`, `AlreadyCorrect`, `Skipped`, `DryRun`, `Failed`, plus `Key` (`Created`) and a final `PolicyState` row with counts.

### Remove-BitlockerPolicy.ps1: undo policy

| Parameter | Default | Meaning |
|---|---|---|
| `-Name` | all | Comma-separated value names to act on. |
| `-All` | `$false` | `$true` removes values (or those in `-Name`) regardless of the backup, instead of restoring. The backup stays. |
| `-DryRun` | `$false` | Report only. |
| `-KeyPath` / `-BackupPath` | the real keys | Testing only. |

Default behavior restores each value to what it was before `Set-BitlockerPolicy.ps1` changed it (a value that was not set originally is removed). Restored entries leave the backup; the backup key and the FVE key are deleted once empty. Encryption, protectors and recovery keys are untouched. A GPO/MDM policy re-applies its own values on its next refresh. With no backup present it reports `NotPresent` and suggests `-All $true`.

### Enable-BitLockerProtectors.ps1: add protectors and encrypt

Adds the requested protectors and, if the volume is fully decrypted, starts encryption with the first one. Idempotent: existing protector types are reported as `AlreadyPresent`. Encryption starts with the first protector in the order Tpm, TpmPin, Password, RecoveryPassword.

Requires the BitLocker module. For the OS drive, or when `Tpm`/`TpmPin` is requested, it requires a present, ready TPM and stops before changing anything otherwise (run `Set-TpmReady.ps1` first).

| Parameter | Default | Meaning |
|---|---|---|
| `-DriveLetter` | system drive | e.g. `C:` or `D`. |
| `-Protectors` | `Tpm,RecoveryPassword` | Comma separated: `Tpm` (TPM only), `TpmPin` (TPM + PIN, needs `-Pin`), `RecoveryPassword` (48-digit password), `Password` (passphrase, needs `-Password`). `Tpm` and `TpmPin` cannot be combined. |
| `-Pin` / `-Password` | none | **Plaintext.** Only checked when `TpmPin` / `Password` is requested. The startup-authentication policy must allow a PIN. |
| `-EncryptionMethod` | `XtsAes256` | `Aes128`, `Aes256`, `XtsAes128`, `XtsAes256`. Used only when encryption starts. |
| `-UsedSpaceOnly` | `$false` | `$true` encrypts only used space (faster); `$false` encrypts the whole volume. |
| `-SkipHardwareTest` | `$true` | `$true` avoids the restart-and-test cycle on OS drives. |
| `-BackupToAD` / `-BackupToEntra` | `$false` | Escrow every recovery password on the drive to AD DS / Entra ID afterwards. |
| `-ReturnRecoveryPassword` | `$true` | Include the recovery password in the output (and therefore in PDQ logs). |
| `-DryRun` | `$false` | Report only. Runs every check (admin, module, TPM, volume), then reports the protectors it would add, whether it would start encryption, and any escrow it would do. Nothing is changed. |

Example:

```powershell
powershell.exe -ExecutionPolicy Bypass -Command "& '.\Enable-BitLockerProtectors.ps1' -DriveLetter C: -Protectors Tpm,RecoveryPassword -BackupToEntra $true -ReturnRecoveryPassword $false"
```

Statuses: `Enabled` (encryption started), `Added`, `AlreadyPresent`, `Backed up`, `DryRun`, `Skipped`, `Failed`. The final `VolumeState` row shows VolumeStatus, Protection, Encrypted %, Method and Protectors. Protection stays Off until encryption completes or the hardware test passes, so confirm with a re-scan rather than the package output alone.

> The script's header comment says `-UsedSpaceOnly` defaults to `$true` and `-ReturnRecoveryPassword` to `$false`. The `param()` block is what runs: `$false` and `$true` as listed above. The table above reflects the `param()` block.

### Remove-BitLockerProtectors.ps1: remove protectors

**Destructive.** Removes the protectors named by `-Protectors` and/or `-KeyProtectorId`; does nothing if neither is given. To decrypt use `Disable-BitLocker.ps1`.

| Parameter | Default | Meaning |
|---|---|---|
| `-DriveLetter` | system drive | Target drive. |
| `-Protectors` | none | Types: `Tpm`, `TpmPin`, `TpmStartupKey`, `TpmPinStartupKey`, `RecoveryPassword`, `Password`, `ExternalKey`, `TpmNetworkKey`, `PublicKey`, `AdAccountOrGroup`, or `All`. `RecoveryKey` and `StartupKey` are aliases for `ExternalKey`. |
| `-KeyProtectorId` | none | Comma-separated `{GUID}` IDs, e.g. one of several recovery passwords. |
| `-Force` | `$false` | Allows leaving an encrypted volume with no RecoveryPassword (or no protector at all). |
| `-DryRun` | `$false` | Report only. |

Guard: on an encrypted volume, a removal that would leave no `RecoveryPassword` (or no protector) is refused with a `Guard` row `Failed` unless `-Force $true`; this also applies under `-DryRun`. Windows may still refuse to remove the last protector of some OS volumes. A locked volume fails in preflight. Typical use is rotating a recovery password: add a new one with `Enable-BitLockerProtectors.ps1`, then remove the old `KeyProtectorId` here.

### Disable-BitLocker.ps1: decrypt

**Destructive.** Runs the real `Disable-BitLocker` cmdlet, which removes all key protectors and decrypts in the background. The final `VolumeState` row shows progress; re-scan to see completion.

| Parameter | Default | Meaning |
|---|---|---|
| `-DriveLetter` | system drive | Target drive. |
| `-Force` | `$false` | `$true` allows decrypting a volume whose protection is On. |
| `-DryRun` | `$false` | Report only. |

Statuses: `Started`, `NothingToDo` (already decrypted), `InProgress` (already decrypting), `Failed` (locked volume, or protection On without `-Force`), `DryRun`.

---

## Reports in PDQ Connect

The scanners' results can be used to build  reports. We recommend at least 3 reports as described below: **TPM Summary**, **Bitlocker status** and **Bitlocker recover passwords**. Every report starts with the device `Name`, then device and scanner columns. Scanner columns are headed `Field (Scanner name)`.

**Report construction:** In Connect, open **Reports**, create a new custom report, choose the device as the row source, add device columns, then add scanner columns from each custom scanner by picking the scanner and then the field. Add filters, save, and export as CSV if needed. 

How reports behave (from the exported files):

- Exports are CSV, one row per device for the TPM scanner, **one row per volume** for the status scanner, and **one row per protector** for the protectors scanner.
- A value the scanner could not read appears as the literal text `null` (also for devices that have no TPM).
- Only devices with scanner data are listed. Check that every device you expect has been scanned (and that the scanner has run on it since it was added) before reading a missing row as "not encrypted".

### Report 1: TPM Summary

Purpose: which devices can use BitLocker with a TPM, and why not.

| Column | Source |
|---|---|
| Name | Device |
| Manufacturer, Model, Architecture | Device |
| IsVirtualMachine, FirmwareType, SecureBootEnabled | TPM Capabilities |
| TpmManufacturer, TpmManufacturerVersion | TPM Capabilities |
| TpmEnabled, TpmReady | TPM Capabilities |
| TpmLockedOut, TpmLockoutCount | TPM Capabilities |

### Report 2: Bitlocker status

Purpose: encryption state per volume and what to do about it.

| Column | Source |
|---|---|
| Name | Device |
| MountPoint, ProtectionStatus, LockStatus, KeyProtectors | Bitlocker Status |
| TpmReady | Bitlocker Status |
| Assessment | Bitlocker Status |
| BitLockerError, BitLockerWarnings | Bitlocker Status |


### Report 3: Bitlocker recover passwords

Purpose: look up a recovery password for a device and check escrow.

| Column | Source |
|---|---|
| Name | Device |
| MountPoint, KeyProtectorType, KeyProtectorId | Bitlocker Protectors |
| RecoveryPassword | Bitlocker Protectors |
| RecoverySource, RecoveryBackup | Bitlocker Protectors |

**Treat this report as secret.** It lists live recovery passwords. Restrict access, do not email or attach exports, and delete downloaded CSVs when done. Filter the report to `KeyProtectorType` containing `RecoveryPassword` so TPM rows (which carry no password) do not clutter it. In the sample, `RecoveryBackup` is `No backup event found` for both devices, meaning no escrow to AD or Entra was logged (consistent with neither `-BackupToAD` nor `-BackupToEntra` having been used).

### Additional reports worth building

Filter wording below is in terms of scanner fields; use the report builder's equivalent operators.

| Report | Filter | Columns |
|---|---|---|
| **Unprotected OS volumes** | `Bitlocker Status` > `IsOsVolume` is true AND `ProtectionStatus` is not `On (1)` | Name, Assessment, ConversionStatus, TpmReady, BitLockerNextStep |
| **Ready to encrypt** | `TpmReady` is true AND `IsOsVolume` is true AND `ConversionStatus` is `FullyDecrypted` | Name, Manufacturer, Model, TpmManufacturer, KeyProtectors |
| **Blocked: TPM not ready** | `TpmQueryStatus` is not `Ok` OR `TpmReady` is false | Name, IsVirtualMachine, TpmQueryStatus, TpmNextStep, FirmwareType |
| **Suspended / paused** | `Assessment` contains `protection is OFF` OR `ConversionStatus` is `EncryptionPaused` | Name, MountPoint, Assessment, PercentEncrypted |
| **Missing recovery password** | `Bitlocker Protectors` > `RecoveryPassword` is `null` AND `KeyProtectorType` contains `RecoveryPassword` | Name, MountPoint, RecoverySource |
| **Escrow gaps** | `RecoveryBackup` is `No backup event found` | Name, MountPoint, KeyProtectorId, RecoveryBackup (omit `RecoveryPassword`) |
| **Scanner health** | `BitLockerQueryStatus` is not `Ok` (or `TpmQueryStatus` is not `Ok`) | Name, BitLockerQueryStatus, BitLockerError, BitLockerNextStep, ScannerRunAs, ScannerElevated |

Escrow gaps is the safe version of the recovery-password report: it identifies devices without logging the secrets.

**Complement from built-in inventory.** Connect's own device inventory already exposes BitLocker partition fields (`protection_status`, `lock_status`, `encryption_method`, `encryption_percentage`, `key_protector`, `volume_status`, `drive_letter`). They are a useful cross-check against the scanner output and need no custom scanner. They do not include recovery passwords, backup status, TPM details or the scanner's `Assessment`.

---

## Troubleshooting

| Symptom | Likely cause / action |
|---|---|
| `BitLockerQueryStatus` or `TpmQueryStatus` = `AccessDenied`, `ScannerElevated` = false | Scanner not running as SYSTEM/administrator. Fix the scanner's run-as setting and rescan. |
| `ModuleMissing` | BitLocker feature (Server) or TPM module not available. See `BitLockerNextStep` / `TpmNextStep`. |
| `NoVolumes` | No encryptable volumes. Check fixed disks; run `manage-bde -status` on the device. |
| `NoTpm` | No TPM exposed. VM: add a vTPM. Hardware: enable TPM/PTT/fTPM in BIOS/UEFI. |
| `ProviderError` or `ScriptError` | Read the `...Error` field; run `manage-bde -status` or `tpm.msc`, check the BitLocker-API and TPM-WMI event logs, send the error text to the script owner. |
| `KeyProtectors` and `RecoveryPassword` null on a volume | Volume is locked; protectors cannot be read. Unlock it. |
| `RecoverySource` = `NotFound` | A recovery protector exists but the password could not be read (not elevated, or locked). |
| `RecoveryBackup` says `No backup event found` | No escrow event in the local log. Either not escrowed or the log rolled over; use `-BackupToAD`/`-BackupToEntra` or verify in AD/Entra. |
| `Enable-BitLockerProtectors`: "TPM not usable" | Run `Set-TpmReady.ps1` first. |
| "Group policy does not permit the use of TPM-only at startup" (0x80310066) | Policy disallows the protector. Check `UseTPM` / `UseTPMPIN` in `Set-BitlockerPolicy.ps1` (current defaults allow both) and re-run `Set-BitlockerPolicy.ps1`. |
| `Set-BitlockerPolicy`: `ManagedPolicy` failed | FVE policy was set by GPO/MDM/someone else. Resolve the owner, or take over with `Remove-BitlockerPolicy.ps1 -All $true`. |
| Device missing from a report | It has not been scanned yet, is offline, or the scanner has not run since it was added. |

---

## Known limitations

- `Set-BitlockerPolicy` detects only policy that is already applied; MDM policy not yet delivered is not detected.
- Some ADMX settings are not in the policy table; the table is the policy.
- No package for suspending/resuming protection, unlocking volumes, or enabling a TPM from the OS.
- These scanners were written for and tested against PDQ Connect. The PDQ Inventory scan profiles in `scanners/` are provided for convenience and have not been tested in PDQ Inventory.
- Scanners read BitLocker through the PowerShell modules only; there is no WMI fallback.
- The scanner `Get-Tpm` fields (`TpmEnabled`, `TpmActivated`, `TpmOwned`, `RestartPending`) and the `Get-BitLockerVolume` enum numbering are assumed to match the provider values; the `ModuleMissing` path of the TPM scanner cannot be mocked.
