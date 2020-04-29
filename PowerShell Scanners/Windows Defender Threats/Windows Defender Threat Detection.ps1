if (-Not(Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue)) {
    throw "Unable to find Get-MpComputerStatus. Available on Windows 10/Server 2016 or higher"
}

$DefenderStatus = (Get-Service WinDefend -ErrorAction SilentlyContinue).Status

if ($DefenderStatus -ne "Running") {
    throw "The Windows Defender service is not currently running"
}

Get-MpThreatDetection