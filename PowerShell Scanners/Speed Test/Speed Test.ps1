# Based on https://pdq-reddit.slack.com/archives/CGDC3CF1S/p1608059965030900
[CmdletBinding()]
param (
    [ValidateRange(0, 100)]
    [Double]$MaxPacketLoss = 2,
    [ValidateRange(0, 100)]
    [Double]$MaxSpeedDifference = 20,
    [Double]$MinDownloadSpeed = 25,
    [Double]$MinUploadSpeed = 4,
    [String]$DownloadUri = 'https://bintray.com/ookla/download/download_file?file_path=ookla-speedtest-1.0.0-win64.zip',
    [String]$DownloadLocation = "$($Env:ProgramData)\SpeedtestCLI"
)

# Disable progress bars. They can cause slowness.
$ProgressPreference = "SilentlyContinue"

# Force all errors to be terminating.
$ErrorActionPreference = "Stop"

# Used for tracking if any of the health checks failed.
$global:HealthPassed = $true

function Get-SpeedDifference {

    param (
        [UInt64]$Old,
        [UInt64]$New
    )

    # Calculate a percentage that shows how much the speed changed.
    # A positive number indicates an increase in speed, negative indicates a decrease.
    # Example -- old:30, new:20, output is -33. 20 is 33% less than 30.
    # Example -- old:20, new:30, output is  50. 30 is 50% more than 20.
    [Math]::Round(($New - $Old) / $Old * 100, 2)

}

function Assert-Limit {

    [CmdletBinding()]
    param (
        [Bool]$Test,
        [String]$Message
    )

    if ( $Test -eq $true ) {

        $global:HealthPassed = $false
        Write-Verbose -Message $Message

    }
    
}



# Create the folder if it doesn't exist, then go to it.
if ( -not (Test-Path -Path $DownloadLocation) ) {

    $null = New-Item -Path $DownloadLocation -ItemType "Directory" -Force
    Write-Verbose -Message "Created '$DownloadLocation'"

} else {

    Write-Verbose -Message "Folder already exists: $DownloadLocation"

}

$CurrentDir = $PWD
Set-Location -Path $DownloadLocation

# Download speedtest.zip and unzip it.
if ( -not (Test-Path -Path "speedtest.exe") ) {

    Write-Verbose -Message "Downloading speedtest.zip"
    Invoke-RestMethod -Uri $DownloadUri -OutFile "speedtest.zip"
    Write-Verbose -Message "Download finished."

    Expand-Archive -Path "speedtest.zip" -DestinationPath . -Force
    Write-Verbose -Message "Unzipped speedtest.zip"
    $null = Remove-Item -Path "speedtest.zip"

}

# Run the test.
Write-Verbose -Message "Running speedtest.exe"
$SpeedtestResultsJson = .\speedtest.exe -f json --accept-license --accept-gdpr
$SpeedtestResults = $SpeedtestResultsJson | ConvertFrom-Json

# Bandwidth is in bytes, so we need to convert it to megabits.
$DownloadSpeed = [Math]::Round($SpeedtestResults.download.bandwidth / 1MB * 8, 2)
$UploadSpeed = [Math]::Round($SpeedtestResults.upload.bandwidth / 1MB * 8, 2)

if ( $SpeedtestResults.packetLoss ) {

    $PacketLoss = [Math]::Round($SpeedtestResults.packetLoss, 2)

} else {

    Write-Verbose -Message "Packet loss is null, which likely means ICMP is blocked on the selected server."
    $PacketLoss = 100

}

# Check the results against the limits.
Assert-Limit -Test ( $DownloadSpeed -lt $MinDownloadSpeed ) -Message "Download speed is lower than $MinDownloadSpeed Mbps"
Assert-Limit -Test ( $UploadSpeed -lt $MinUploadSpeed ) -Message "Upload speed is lower than $MinUploadSpeed Mbps"
Assert-Limit -Test ( $PacketLoss -gt $MaxPacketLoss ) -Message "Packet loss is higher than $MaxPacketLoss%"

# Compare against previous results.
if ( Test-Path "PreviousResults.json" ) {

    $PreviousResults = Get-Content -Path "PreviousResults.json" | ConvertFrom-Json

    $DownloadDifference = Get-SpeedDifference -Old $PreviousResults.download.bandwidth -New $SpeedtestResults.download.bandwidth
    Assert-Limit -Test ( $DownloadDifference -lt -$MaxSpeedDifference ) -Message "Download speed is more than $MaxSpeedDifference% lower than previous test"
    
    $UploadDifference = Get-SpeedDifference -Old $PreviousResults.upload.bandwidth -New $SpeedtestResults.upload.bandwidth
    Assert-Limit -Test ( $UploadDifference -lt -$MaxSpeedDifference ) -Message "Upload speed is more than $MaxSpeedDifference% lower than previous test"

}

# Save the results.
$SpeedtestResultsJson | Out-File -FilePath "PreviousResults.json" -Force

# Create the object.
[PSCustomObject]@{
    "Download Speed"      = [Double]$DownloadSpeed
    "Upload Speed"        = [Double]$UploadSpeed
    "Packet Loss"         = [Double]$PacketLoss
    "Latency"             = [UInt32]$SpeedtestResults.ping.latency
    "Jitter"              = [UInt32]$SpeedtestResults.ping.jitter
    "Health Passed"       = [Bool]  $global:HealthPassed
    "ISP"                 = [String]$SpeedtestResults.isp
    "External IP"         = [String]$SpeedtestResults.interface.externalIp
    "Internal IP"         = [String]$SpeedtestResults.interface.internalIp
    "Server Used"         = [String]$SpeedtestResults.server.host
    "Results URL"         = [String]$SpeedtestResults.result.url
    "Download Difference" = [Double]$DownloadDifference
    "Upload Difference"   = [Double]$UploadDifference
}

# Restoring the original path isn't necessary for Inventory, but it's really handy when manually testing this script :)
Set-Location -Path $CurrentDir