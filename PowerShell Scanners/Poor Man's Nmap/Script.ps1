# Poor man's nmap - PDQ Connect PowerShell scanner edition.
# Auto-detects the local subnet, parallel ICMP sweep, then TCP-connect probes
# common ports on each live host. Emits ONE OBJECT PER LISTENING HOST so the
# scanner maps the properties to columns (IPAddress, Hostname, MAC, OpenPorts).
# No params, no Format-Table, no ConvertTo-Csv - those produce strings, and the
# scanner would just reflect String.Length into a bogus "Length" column.

# --- Config (edit here instead of params) ------------------------------------
$Ports     = @(21,22,23,25,53,80,110,135,139,143,389,443,445,587,993,995,1433,3306,3389,5432,5900,8080,8443)
$TimeoutMs = 500

$ServiceNames = @{
    21='ftp'; 22='ssh'; 23='telnet'; 25='smtp'; 53='dns'; 80='http'; 110='pop3'
    135='msrpc'; 139='netbios'; 143='imap'; 389='ldap'; 443='https'; 445='smb'
    587='submission'; 993='imaps'; 995='pop3s'; 1433='mssql'; 3306='mysql'
    3389='rdp'; 5432='postgres'; 5900='vnc'; 8080='http-alt'; 8443='https-alt'
}

function Get-IPRange {
    param([Parameter(Mandatory)][string]$CIDR)
    $parts  = $CIDR -split '/'
    $base   = [System.Net.IPAddress]::Parse($parts[0])
    $prefix = [int]$parts[1]

    $bytes = $base.GetAddressBytes()
    [Array]::Reverse($bytes)
    $ipInt = [System.BitConverter]::ToUInt32($bytes, 0)

    if ($prefix -eq 0) { $mask = [uint32]0 }
    else { $mask = [uint32](([math]::Pow(2, $prefix) - 1)) -shl (32 - $prefix) }

    $network   = [uint32]($ipInt -band $mask)
    $hostBits  = [uint32]((-bnot $mask) -band [uint32]::MaxValue)
    $broadcast = [uint32]($network -bor $hostBits)

    if ($prefix -ge 31) { $lo = [int64]$network; $hi = [int64]$broadcast }
    else { $lo = [int64]$network + 1; $hi = [int64]$broadcast - 1 }

    for ($i = $lo; $i -le $hi; $i++) {
        $b = [System.BitConverter]::GetBytes([uint32]$i)
        [Array]::Reverse($b)
        ([System.Net.IPAddress]::new($b)).IPAddressToString
    }
}

# --- Auto-detect the local subnet --------------------------------------------
$cfg = Get-NetIPConfiguration -ErrorAction SilentlyContinue |
    Where-Object { $_.IPv4DefaultGateway -and $_.NetAdapter.Status -eq 'Up' } |
    Select-Object -First 1
if (-not $cfg) { throw "Could not auto-detect an active IPv4 network." }
$Cidr = "$($cfg.IPv4Address.IPAddress)/$($cfg.IPv4Address.PrefixLength)"

$targets = @(Get-IPRange -CIDR $Cidr)

# --- Host discovery (parallel ICMP, batched) ---------------------------------
$live  = New-Object System.Collections.Generic.List[string]
$batch = 256
for ($i = 0; $i -lt $targets.Count; $i += $batch) {
    $slice = $targets[$i..([math]::Min($i + $batch - 1, $targets.Count - 1))]
    $pingers = foreach ($ip in $slice) {
        $p = [System.Net.NetworkInformation.Ping]::new()
        [PSCustomObject]@{ IP = $ip; Pinger = $p; Task = $p.SendPingAsync($ip, $TimeoutMs) }
    }
    try { [void][System.Threading.Tasks.Task]::WaitAll([System.Threading.Tasks.Task[]]($pingers.Task), $TimeoutMs + 1000) } catch {}
    foreach ($pg in $pingers) {
        if ($pg.Task.Status -eq [System.Threading.Tasks.TaskStatus]::RanToCompletion -and
            $pg.Task.Result.Status -eq 'Success') {
            $live.Add($pg.IP)
        }
        $pg.Pinger.Dispose()
    }
}

# --- Port scan + enrichment (emit only LISTENING hosts) ----------------------
$results = foreach ($ip in $live) {
    $conns = foreach ($port in $Ports) {
        $c = [System.Net.Sockets.TcpClient]::new()
        [PSCustomObject]@{ Port = $port; Client = $c; Task = $c.ConnectAsync($ip, $port) }
    }
    try { [void][System.Threading.Tasks.Task]::WaitAll([System.Threading.Tasks.Task[]]($conns.Task), $TimeoutMs) } catch {}

    $open = foreach ($cn in $conns) {
        $isOpen = ($cn.Task.Status -eq [System.Threading.Tasks.TaskStatus]::RanToCompletion -and $cn.Client.Connected)
        $cn.Client.Close()
        if ($isOpen) {
            $name = $ServiceNames[[int]$cn.Port]
            if ($name) { "$($cn.Port)/$name" } else { "$($cn.Port)" }
        }
    }
    $open = @($open)
    if ($open.Count -eq 0) { continue }   # skip hosts with nothing listening

    $hostname = try { [System.Net.Dns]::GetHostEntry($ip).HostName } catch { '' }

    $mac = ''
    try {
        $n = Get-NetNeighbor -IPAddress $ip -ErrorAction Stop |
             Where-Object { $_.LinkLayerAddress } | Select-Object -First 1
        if ($n) { $mac = $n.LinkLayerAddress }
    } catch {
        $arpLine = (arp -a $ip 2>$null | Select-String $ip)
        if ($arpLine -match '([0-9a-fA-F]{2}[-:]){5}[0-9a-fA-F]{2}') { $mac = $Matches[0] }
    }

    [PSCustomObject]@{
        IPAddress = $ip
        Hostname  = $hostname
        MAC       = $mac
        OpenPorts = ($open -join ', ')
    }
}

# Emit objects to the pipeline -> scanner builds one column per property,
# one row per listening host.
$results | Sort-Object { [System.Version]$_.IPAddress }
