[CmdletBinding()]
param(
	# attempt NBTStat -A on each entry
	[Boolean]$AddNbtName = $true,

	# Add reverse lookup of each neighbor IP. PTR records must be enabled
	[Boolean]$AddReverseLookup = $true
)

# Grab the ARP cache and filter out broadcast and multicast
$neighbors = Get-NetNeighbor | Where-Object {
	($_.LinkLayerAddress -ne "") -and
	($_.LinkLayerAddress -ne "FF-FF-FF-FF-FF-FF") -and # Broadcast
	($_.LinkLayerAddress -notlike "01-00-5E-*") -and # IPv4 multicast
	($_.LinkLayerAddress -notlike "33-33-*") } # IPV6 multicast

# Process each neighbor and add additional information
foreach ($neighbor in $neighbors) {

	if ($AddReverseLookup) {

		# Check DNS for the hostname associated with this IP
		try {

			$DNSName = [System.Net.Dns]::GetHostEntry($neighbor.IPAddress).hostname

		} catch {

			Write-Verbose "Unable to resolve host $($neighbor.IPAddress)"

		}
	}

	if ($AddNbtName) {

		# Runs nbtstat, matches the output to regex, then grabs the match at index 1
		$nbtstat = nbtstat -A $neighbor.IPAddress |
		Where-Object { $_ -match '^\s*([^<\s]+)\s*<00>\s*UNIQUE' } |
		ForEach-Object { $matches[1] }

	}

	# Output some properties
	$neighbor | Select-Object IfIndex, InterfaceAlias, IPAddress, State, Store, LinkLayerAddress,
	@{ name = 'NetBiosName'; expression = { $nbtstat } },
	@{ name = 'ReverseLookup'; expression = { $DNSName } }

}