$tempPath = $env:TEMP
$TagFile = Join-Path -Path $tempPath -ChildPath "servicetag.csv"
$WarrantyFile = Join-Path -Path $tempPath -ChildPath "warranty.csv"
$cliPath = "C:\Program Files (x86)\Dell\CommandIntegrationSuite\DellWarranty-CLI.exe" #https://www.dell.com/support/kbdoc/en-us/000146749/dell-command-warranty
#to install silent the exe switch is /Q /v/qn

$CacheDays = 30

# 1. Get Service Tag
$ServiceTag = (Get-CimInstance Win32_BIOS).SerialNumber

# 2. Determine if we need to run a fresh scan
$NeedsUpdate = $true
if (Test-Path $WarrantyFile) {
    $FileAge = (Get-Date) - (Get-Item $WarrantyFile).LastWriteTime
    if ($FileAge.Days -lt $CacheDays) {
        $NeedsUpdate = $false
    }
}

# 3. Run the EXE only if needed
if ($NeedsUpdate) {
    if (Test-Path $cliPath) {
        $ServiceTag | Out-File -FilePath $TagFile -Encoding ascii
        & $cliPath /I="$TagFile" /E="$WarrantyFile" *> $null
        if (Test-Path $TagFile) { Remove-Item $TagFile -Force }
    }
    else {
        return [PSCustomObject]@{
            "Service Tag"         = $ServiceTag
            "Warranty Start Date" = $null
            "Warranty End Date"   = $null
            "Status"              = "CLI Tool Not Installed"
        }
    }
}

# 4. Import and Parse the (New or Cached) file
if ((Test-Path $WarrantyFile) -and (Get-Item $WarrantyFile).Length -gt 0) {
    $rawCSV = Import-Csv -Path $WarrantyFile

    $latestStart = ($rawCSV | ForEach-Object { [datetime]$_."Start Date" } | Sort-Object -Descending | Select-Object -First 1)
    $latestEnd   = ($rawCSV | ForEach-Object { [datetime]$_."End Date" }   | Sort-Object -Descending | Select-Object -First 1)

    $Result = [PSCustomObject]@{
        "Service Tag"         = $ServiceTag
        "Warranty Start Date" = $latestStart.ToString("yyyy-MM-dd")
        "Warranty End Date"   = $latestEnd.ToString("yyyy-MM-dd")
        "Status"              = if ($NeedsUpdate) { "Fresh Scan" } else { "Cached (Age: $($FileAge.Days) days)" }
    }
}
else {
    $Result = [PSCustomObject]@{
        "Service Tag"         = $ServiceTag
        "Warranty Start Date" = $null
        "Warranty End Date"   = $null
        "Status"              = "No Warranty Data Found"
    }
}

return $Result