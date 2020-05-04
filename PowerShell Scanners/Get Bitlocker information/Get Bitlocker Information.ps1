if (-Not(Get-Command Get-BitlockerVolume -ErrorAction SilentlyContinue)) {
    throw "Unable to find Get-BitlockerVolume. Available on Windows 10 or Server 2016 with the Bitlocker feature installed"
}

Get-BitlockerVolume