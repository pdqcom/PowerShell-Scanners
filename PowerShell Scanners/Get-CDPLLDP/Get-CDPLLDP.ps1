<#
.SYNOPSIS
    Ultra-silent pktmon CDP/LLDP discovery with
    cleaned neighbor/port strings.
#>
[CmdletBinding()]
param (
    [int]$MaxAttempts = 10, #As a PDQ Connect scanner, it will time out after 2 min, change this to 2 but you might not capture the elusive packets in that time
    [int]$CaptureSecondsPerAttempt = 30, #Alternatively run as an automated package or scheduled task
    [switch]$IncludeLLDP = $true,
    [switch]$ClearCache
)

# Admin check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    return [PSCustomObject]@{
        Date                   = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ssZ")
        NeighborDeviceName     = "ERROR: Administrator privileges required"
        NeighborDevicePort     = "ERROR: Administrator privileges required"
        NeighborDevicePortDesc = "ERROR: Administrator privileges required"
        Protocol               = "N/A"
    }
}

$CacheFile = Join-Path $env:TEMP -ChildPath "CDP_LLDPCache.json"

# Load cache
if ((Test-Path $CacheFile) -and -not $ClearCache) {
    try {
        $CachedRecords = Get-Content $CacheFile -Raw | ConvertFrom-Json
        # Flatten incoming cached objects to ensure dates are plain strings
        if ($CachedRecords) {
            $CachedRecords = @($CachedRecords) | ForEach-Object {
                $CleanDate = if ($_.Date -like '@{value=*') { (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ssZ") } else { [string]$_.Date }
                [PSCustomObject]@{
                    Date                   = $CleanDate
                    NeighborDeviceName     = [string]$_.NeighborDeviceName
                    NeighborDevicePort     = [string]$_.NeighborDevicePort
                    NeighborDevicePortDesc = [string]$_.NeighborDevicePortDesc
                    Protocol               = [string]$_.Protocol
                }
            }
        }
    } catch { 
        $CachedRecords = @() 
    }
} else {
    $CachedRecords = @()
}

# Check Ethernet
$EthernetUp = Get-NetAdapter -Physical -ErrorAction SilentlyContinue |
    Where-Object { $_.Status -eq 'Up' -and $_.MediaType -eq '802.3' }

if (-not $EthernetUp) {
    if ($CachedRecords.Count -eq 0) {
        return [PSCustomObject]@{
            Date                   = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ssZ")
            NeighborDeviceName     = "No neighbor found"
            NeighborDevicePort     = "No neighbor found"
            NeighborDevicePortDesc = "No neighbor found"
            Protocol               = "N/A"
        }
    } else {
        return $CachedRecords
    }
}

# === Ethernet connected - capture ===
$Seen = @{}
$NewResults = @()

foreach ($item in $CachedRecords) {
    $Key = "$($item.NeighborDeviceName)|$($item.NeighborDevicePort)"
    if (-not $Seen.ContainsKey($Key)) {
        $Seen[$Key] = $true 
    }
}

for ($Attempt = 1; $Attempt -le $MaxAttempts; $Attempt++) {
    $Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $EtlFile = Join-Path $env:TEMP -ChildPath "Discovery_${Timestamp}.etl"
    $TxtFile = $EtlFile -replace '\.etl$', '.txt'

    try {
        pktmon filter remove *> $null 2>&1
        pktmon filter add -m 01-00-0C-CC-CC-CC *> $null 2>&1
        if ($IncludeLLDP) {
            pktmon filter add -d 0x88cc *> $null 2>&1
        }

        pktmon start --capture --pkt-size 0 --file-name $EtlFile --comp nics *> $null 2>&1
        Start-Sleep -Seconds $CaptureSecondsPerAttempt
        pktmon stop *> $null 2>&1

        pktmon etl2txt $EtlFile -o $TxtFile --verbose 3 *> $null 2>&1

        $Content = Get-Content $TxtFile -Raw -ErrorAction SilentlyContinue
        if (-not $Content) { continue }

<#
        # =========================================================================
        # DEBUG BLOCK: Output human-readable packet text windows containing data
        # =========================================================================
        $DebugSections = $Content -split '(?i)\[\d+\]\d{4}\.\d+::'
        foreach ($DSection in $DebugSections) {
            if ($DSection -match 'Device-ID|Chassis ID|System Name|Port-ID|Port ID') {
                Write-Host "`n" -NoNewline
                Write-Host "==================== [RAW DISCOVERY PACKET FRAME] ====================" -ForegroundColor Cyan
                Write-Host $DSection.Trim() -ForegroundColor White
                Write-Host "======================================================================" -ForegroundColor Cyan
                Write-Host "`n" -NoNewline
            }
        }
        # =========================================================================
#>

        $Sections = $Content -split '(?i)\[\d+\]\d{4}\.\d+::'

        foreach ($Section in $Sections) {
            if ($Section -match 'Device-ID|Chassis ID|System Name|Port-ID|Port ID') {
                
                $Device   = ""
                $Port     = ""
                $PortDesc = ""

                # Read line-by-line to avoid multi-line regex matching jumps
                $Lines = $Section -split '\r?\n'
                for ($i = 0; $i -lt $Lines.Count; $i++) {
                    $Line = $Lines[$i]

                    # 1. Capture Device Name
                    if ($Line -match '(?i)(?:Device-ID|System Name TLV)') {
                        if ($Line -match ':\s*(.*)$' -and $Matches[1] -and $Matches[1] -notmatch 'length') {
                            $Device = $Matches[1]
                        } elseif ($i + 1 -lt $Lines.Count -and $Lines[$i+1] -match ':\s*(.*)$') {
                            $Device = $Matches[1]
                        }
                    }

                    # 2. Capture Port ID
                    if ($Line -match '(?i)(?:Port-ID|Port ID TLV)') {
                        if ($Line -match ':\s*(.*)$' -and $Matches[1] -and $Matches[1] -notmatch 'length') {
                            $Port = $Matches[1]
                        } elseif ($i + 1 -lt $Lines.Count -and $Lines[$i+1] -match ':\s*(.*)$') {
                            $Port = $Matches[1]
                        }
                    }

                    # 3. Capture Port Description
                    if ($Line -match '(?i)Port Description TLV') {
                        if ($Line -match ':\s*(.*)$') {
                            $PortDesc = $Matches[1]
                        }
                    }
                }

                # Fallback safely: if explicit Port ID isn't found, try Port Description
                if ([string]::IsNullOrWhiteSpace($Port)) { $Port = $PortDesc }

                # Strip trailing line data artifacts
                $Device   = $Device -replace '\s*(?:value length|bytes|TLV|Subtype|\(|,).*$', '' -replace '\s*0x.*$', ''
                $Port     = $Port -replace '\s*(?:value length|bytes|TLV|Subtype|\(|,).*$', '' -replace '\s*0x.*$', ''
                $PortDesc = $PortDesc -replace '\s*(?:value length|bytes|TLV|Subtype|\(|,).*$', '' -replace '\s*0x.*$', ''
                
                # Dynamic clean array to strip out wrapping spaces, quotes, and carriage returns
                $TrimChars = @(' ', "'", '"', '`', '(', ')', "`r")
                $Device   = $Device.Trim($TrimChars)
                $Port     = $Port.Trim($TrimChars)
                $PortDesc = $PortDesc.Trim($TrimChars)

                # Skip if the text output parses down to generic metadata tags or empty lines
                if ([string]::IsNullOrWhiteSpace($Device) -or [string]::IsNullOrWhiteSpace($Port) -or $Device -ieq "TLV" -or $Port -ieq "TLV" -or $Device -match '^\d+$') {
                    continue
                }

                $Key = "$Device|$Port"
                if (-not $Seen.ContainsKey($Key) -and $Device.Length -gt 1 -and $Port.Length -gt 1) {
                    $Seen[$Key] = $true

                    $NewResults += [PSCustomObject]@{
                        Date                   = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ssZ")
                        NeighborDeviceName     = $Device
                        NeighborDevicePort     = $Port
                        NeighborDevicePortDesc = $PortDesc
                        Protocol               = if ($Section -match '0x88cc|LLDP') { "LLDP" } else { "CDP" }
                    }
                }
            }
        }

        if ($NewResults.Count -gt 0) {
            break
        }
    }
    finally {
        @($EtlFile, $TxtFile) | ForEach-Object {
            if (Test-Path $_) { Remove-Item $_ -Force -ErrorAction SilentlyContinue }
        }
    }

    if ($Attempt -lt $MaxAttempts) {
        Start-Sleep -Seconds 5
    }
}

# Merge arrays together
$AllRecords = $NewResults + $CachedRecords

# Force older deserialized date objects to fall flat into pure strings during formatting pipeline
$FinalRecords = $AllRecords | ForEach-Object {
    [PSCustomObject]@{
        Date                   = [string]($_.Date)
        NeighborDeviceName     = [string]($_.NeighborDeviceName)
        NeighborDevicePort     = [string]($_.NeighborDevicePort)
        NeighborDevicePortDesc = [string]($_.NeighborDevicePortDesc)
        Protocol               = [string]($_.Protocol)
    }
} | Select-Object -First 5

# Save cache
$FinalRecords | ConvertTo-Json -Depth 3 | Set-Content $CacheFile -Force

# Cleanup pktmon filters before exiting
pktmon filter remove *> $null 2>&1

# Return Results
if ($FinalRecords.Count -eq 0) {
    return [PSCustomObject]@{
        Date                   = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ssZ")
        NeighborDeviceName     = "No neighbor found"
        NeighborDevicePort     = "No neighbor found"
        NeighborDevicePortDesc = "No neighbor found"
        Protocol               = "N/A"
    }
} else {
    return $FinalRecords
}
