# Inspired by the comments on the below blog post
# https://blogs.msdn.microsoft.com/powershell/2019/01/18/parsing-text-with-powershell-1-3/

# Or use Get-NetTCPConnection if it's available ¯\_(ツ)_/¯


Function Get-Netstat {

    # Regex to group each Netstat line into 4 groups
    $netstatMatchPattern = '^\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)\s+(.+)$'

    # Regex to match and IPv4 or IPV6 IP and Port as per Netstat's output
    $netstatIPMatchPattern = '^(.+):([0-9]+)$'

    # Run 'netstat -ano' and capture the output. Skip the first 4 lines, and match against our regex
    $netstatOutput = netstat.exe -ano | Select-Object -Skip 4 | Select-String -Pattern $netstatMatchPattern 

    $netstatOutput| ForEach-Object {
        $protocol, $localAddress, $foreignAddress, $state, $processId = $_.Matches[0].Groups[1..5].value
        $localAddressAndPort = $localAddress | Select-String -Pattern $netstatIPMatchPattern
        $foreignAddressAndPort = $foreignAddress | Select-String -Pattern $netstatIPMatchPattern

        [PSCustomObject] @{
            Protocol = $protocol
            LocalAddress = $localAddressAndPort.Matches[0].Groups[1].Value
            LocalPort = $localAddressAndPort.Matches[0].Groups[2].Value
            ForeignAddress = $foreignAddressAndPort.Matches[0].Groups[1].Value
            ForeignPort = $foreignAddressAndPort.Matches[0].Groups[2].Value
            State = $state
            ProcessID = $processId
            ProcessName = (Get-Process -Id $processId).Name
        }
    }

}

Get-Netstat | Out-GridView -Title 'PowerShell ❤ Netstat'