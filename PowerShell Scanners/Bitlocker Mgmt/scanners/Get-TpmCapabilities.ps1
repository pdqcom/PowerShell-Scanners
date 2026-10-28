<#
.SYNOPSIS
    PDQ Connect scanner: TPM state and platform capabilities.

.DESCRIPTION
    Emits one object per device. Coded values are shown as "Name (value)". Values that
    can't be read are $null, and TpmPresent is $null when the TPM query couldn't answer.
    Reads the TPM with Get-Tpm (TrustedPlatformModule module). Get-Tpm has no spec version, so
    TpmSpecVersion is the one value still read from Win32_Tpm; it is $null with a warning if
    that read fails.

    TpmQueryStatus is Ok, NoTpm, ModuleMissing, AccessDenied, ProviderError or ScriptError.
    TpmError and TpmNextStep explain a failure; TpmWarnings lists partial ones.

    Run as SYSTEM or a local administrator. Compatible with Windows PowerShell 5.1.
#>

$ErrorActionPreference = 'Stop'

# TCG TPM Vendor ID registry: vendor code -> name
$TpmVendors = @{
    AMD  = 'AMD'; AMZN = 'Amazon';
    ATML = 'Atmel'; BRCM = 'Broadcom';
    CSCO = 'Cisco'; FLYS = 'Flyslice Technologies';
    GOOG = 'Google'; HPE  = 'Hewlett Packard Enterprise';
    HPI  = 'HP Inc.'; IBM  = 'IBM';
    IFX  = 'Infineon'; INTC = 'Intel';
    LEN  = 'Lenovo'; MSFT = 'Microsoft';
    NSM  = 'National Semiconductor'; NTC  = 'Nuvoton Technology';
    NTZ  = 'Nationz Technologies'; QCOM = 'Qualcomm';
    ROCC = 'Fuzhou Rockchip'; SMSC = 'SMSC';
    SMSN = 'Samsung'; SNS  = 'Sinosun';
    STM  = 'STMicroelectronics'; TXN  = 'Texas Instruments';
    VMW  = 'VMware'; WEC  = 'Winbond'
}

$FirmwareNames = @{ 1 = 'Legacy BIOS'; 2 = 'UEFI' }

$NextSteps = @{
    AccessDenied  = 'Get-Tpm requires administrator rights. Run the scanner as SYSTEM or a local administrator (see ScannerRunAs / ScannerElevated in this output) and rescan.'
    ModuleMissing = 'The TrustedPlatformModule PowerShell module (Get-Tpm) is not available. It ships with Windows 8 / Server 2012 and later; check the Windows version.'
    NoTpm         = 'No TPM is exposed to Windows. On a VM, add a virtual TPM. On hardware, enable it in BIOS/UEFI setup (often named "TPM", "PTT" or "fTPM") if one is expected on this device.'
    ProviderError = 'Unexpected Get-Tpm failure. On the device run "tpm.msc", check Event Viewer > Applications and Services Logs > Microsoft > Windows > TPM-WMI, and send this TpmError text to the script owner.'
}

$script:Warnings = [System.Collections.Generic.List[string]]::new()

function Format-TpmManufacturer($manufacturerId) {
    # ManufacturerId is a DWORD of four ASCII characters, e.g. 0x494E5443 = 'INTC'
    if ($null -eq $manufacturerId) { return $null }
    $bytes = [BitConverter]::GetBytes([uint32]$manufacturerId)
    [array]::Reverse($bytes)
    $code = [Text.Encoding]::ASCII.GetString($bytes).Trim([char[]](0, 32))
    $name = if ($TpmVendors.ContainsKey($code)) { $TpmVendors[$code] } else { 'Unknown' }
    '{0} ({1} 0x{2:X8})' -f $name, $code, [uint32]$manufacturerId
}

function Get-TpmFailure($errorRecord) {
    $exception = $errorRecord.Exception
    $native = if ($exception.PSObject.Properties['NativeErrorCode']) { [string]$exception.NativeErrorCode }
    $text = "$native $($exception.Message)"
    $status = if ($text -match 'AccessDenied|Access denied|UnauthorizedAccess') { 'AccessDenied' } else { 'ProviderError' }
    @{
        Status   = $status
        Detail   = '{0}: {1} [NativeErrorCode={2}, HResult=0x{3:X8}]' -f $exception.GetType().Name, $exception.Message.Trim(), $native, $exception.HResult
        NextStep = $NextSteps[$status]
    }
}

function Get-TpmInfo {
    $summary = [ordered]@{
        TpmQueryStatus         = $null
        TpmPresent             = $null
        TpmEnabled             = $null
        TpmActivated           = $null
        TpmOwned               = $null
        TpmReady               = $null
        TpmSpecVersion         = $null
        TpmManufacturer        = $null
        TpmManufacturerVersion = $null
        TpmLockedOut           = $null
        TpmLockoutCount        = $null
        TpmLockoutMax          = $null
        TpmRestartRequired     = $null
        TpmAutoProvisioning    = $null
        TpmManagedAuthLevel    = $null
        TpmOwnerClearDisabled  = $null
        TpmError               = $null
        TpmNextStep            = $null
    }

    if (-not (Get-Command Get-Tpm -ErrorAction SilentlyContinue)) {
        $summary.TpmQueryStatus = 'ModuleMissing'
        $summary.TpmError       = 'Get-Tpm is unavailable (TrustedPlatformModule module missing).'
        $summary.TpmNextStep    = $NextSteps.ModuleMissing
        return $summary
    }
    try {
        $tpm = Get-Tpm
    } catch {
        $failure = Get-TpmFailure $_
        $summary.TpmQueryStatus = $failure.Status
        $summary.TpmError       = $failure.Detail
        $summary.TpmNextStep    = $failure.NextStep
        return $summary
    }
    if (-not $tpm) {
        # Get-Tpm writes nothing at all when it isn't elevated
        $elevated = (Get-ScannerContext).ScannerElevated
        $summary.TpmQueryStatus = if ($elevated) { 'ProviderError' } else { 'AccessDenied' }
        $summary.TpmError       = 'Get-Tpm returned nothing.'
        $summary.TpmNextStep    = $NextSteps[$summary.TpmQueryStatus]
        return $summary
    }
    if (-not $tpm.TpmPresent) {
        $summary.TpmQueryStatus = 'NoTpm'
        $summary.TpmPresent     = $false
        $summary.TpmError       = 'Get-Tpm reports no TPM present.'
        $summary.TpmNextStep    = $NextSteps.NoTpm
        return $summary
    }

    $summary.TpmQueryStatus         = 'Ok'
    $summary.TpmPresent             = $true
    $summary.TpmManufacturer        = Format-TpmManufacturer $tpm.ManufacturerId
    $summary.TpmManufacturerVersion = $tpm.ManufacturerVersion
    $fields = @{
        TpmEnabled = 'TpmEnabled'; TpmActivated = 'TpmActivated'; TpmOwned = 'TpmOwned'; TpmReady = 'TpmReady'
        TpmLockedOut = 'LockedOut'; TpmLockoutCount = 'LockoutCount'; TpmLockoutMax = 'LockoutMax'
        TpmRestartRequired = 'RestartPending'; TpmAutoProvisioning = 'AutoProvisioning'
        TpmOwnerClearDisabled = 'OwnerClearDisabled'
    }
    foreach ($name in $fields.Keys) { $summary[$name] = $tpm.($fields[$name]) }
    if ($null -ne $tpm.ManagedAuthLevel) { $summary.TpmManagedAuthLevel = [string]$tpm.ManagedAuthLevel }

    # SpecVersion is "2.0, 0, 1.38" (version, revision, errata)
    try {
        $wmiTpm = @(Get-CimInstance -Namespace 'root/cimv2/Security/MicrosoftTpm' -ClassName Win32_Tpm)[0]
        if ($wmiTpm.SpecVersion) { $summary.TpmSpecVersion = ([string]$wmiTpm.SpecVersion -split ',')[0].Trim() }
    } catch {
        $script:Warnings.Add("Win32_Tpm.SpecVersion unreadable ($($_.Exception.Message.Trim())); TpmSpecVersion is null.")
    }

    $summary
}

function Get-PlatformInfo {
    $platform = [ordered]@{ FirmwareType = $null; SecureBootEnabled = $null; IsVirtualMachine = $null }

    try {
        if (-not ('TpmScanner.NativeFirmware' -as [type])) {
            Add-Type -Namespace TpmScanner -Name NativeFirmware -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError = true)]
public static extern bool GetFirmwareType(out uint firmwareType);
'@
        }
        [uint32]$firmwareType = 0
        if (-not [TpmScanner.NativeFirmware]::GetFirmwareType([ref]$firmwareType)) {
            throw "GetFirmwareType failed (Win32 error $([Runtime.InteropServices.Marshal]::GetLastWin32Error()))"
        }
        $fwName = if ($FirmwareNames.ContainsKey([int]$firmwareType)) { $FirmwareNames[[int]$firmwareType] } else { 'Unknown' }
        $platform.FirmwareType = '{0} ({1})' -f $fwName, $firmwareType
    } catch {
        $script:Warnings.Add("Firmware type unreadable ($($_.Exception.Message.Trim())); FirmwareType is null.")
    }

    # The key is absent on legacy BIOS, so a missing value is not a warning
    $secureBoot = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State' -Name UEFISecureBootEnabled -ErrorAction SilentlyContinue
    if ($secureBoot) { $platform.SecureBootEnabled = [bool]$secureBoot.UEFISecureBootEnabled }

    try {
        $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
        # Heuristic on manufacturer and model; a physical Hyper-V host is not flagged
        $platform.IsVirtualMachine = "$($computerSystem.Manufacturer) $($computerSystem.Model)" -match 'Virtual Machine|VMware|VirtualBox|KVM|QEMU|Xen|Parallels|Bochs|HVM domU|Google Compute Engine|Amazon EC2'
    } catch {
        $script:Warnings.Add("Win32_ComputerSystem failed ($($_.Exception.Message.Trim())); IsVirtualMachine is null.")
    }

    $platform
}

function Get-ScannerContext {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    [ordered]@{
        ScannerRunAs    = $identity.Name
        ScannerElevated = ([Security.Principal.WindowsPrincipal]$identity).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
}

try {
    $output = [ordered]@{}
    foreach ($section in (Get-TpmInfo), (Get-PlatformInfo), (Get-ScannerContext)) {
        foreach ($key in $section.Keys) { $output[$key] = $section[$key] }
    }
    $output['TpmWarnings'] = if ($script:Warnings.Count) { $script:Warnings -join '; ' } else { $null }
} catch {
    # Always emit a row so the device shows up with a diagnosis
    $output = [ordered]@{
        TpmQueryStatus = 'ScriptError'
        TpmPresent     = $null
        TpmError       = '{0}: {1} (line {2})' -f $_.Exception.GetType().Name, $_.Exception.Message.Trim(), $_.InvocationInfo.ScriptLineNumber
        TpmNextStep    = 'Unexpected scanner failure. Send this TpmError text to the script owner.'
    }
}

[pscustomobject]$output
