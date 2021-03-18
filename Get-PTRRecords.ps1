# Get Reverse Lookup Zones
$ReverseLookupZones = Get-DnsServerZone -computername efwhqdc01.int.efwnow.com | Where Zone -eq "int.efwnow.com" -and IsReverseLookupZone -eq $True | Where IsAutoCreated -eq $False
 
foreach ($ReverseLookupZone in $ReverseLookupZones)
{
	# Clear Variables
	$Servers = $Null;
 
	# Get Zone Information
	$DNSZoneName = $ReverseLookupZone.ZoneName
 
	# Get IP Information
	$ReverseIP = $ReverseLookupZone.ZoneName.TrimEnd(".in-addr.arpa");
	$ReverseIPSuffix = $ReverseIP.Split(".")
	[array]::reverse($ReverseIPSuffix)
	$ReverseIPSuffix = $ReverseIPSuffix -join "."
 
	# Get Servers
	$Servers = Get-DnsServerResourceRecord -ZoneName $DNSZoneName | Where HostName -ne "@"
 
	foreach ($Server in $Servers)
	{		
		# Get Server IP Address
		$ServerHostName = $Server.HostName
		$ServerIPSuffix = $ServerHostName.Split(".")
		[array]::reverse($ServerIPSuffix)
		$ServerIPSuffix = $ServerIPSuffix -join "."
		$ServerIPAddress = $ReverseIPSuffix + "." + $ServerIPSuffix
 
		# Get Server DNS Hostname
		$ServerDNSName = $Server.RecordData.PtrDomainName
		$ServerDNSName = $ServerDNSName.TrimEnd(".")
 
		Write-Host Working on $ServerDNSName ..
 
		# Get Server DNS Subnet
		$ServerDNSSubnet = $ServerIPAddress.Split(".")[0] + "." + $ServerIPAddress.Split(".")[1] + "." + $ServerIPAddress.Split(".")[2] + ".0/24"
 
		# Resolve DNS Name
		$DNSName = (Resolve-DnsName $ServerDNSName)
 
		if ($DNSName)
		{
			# Clear Values
			$Control = 0;
 
			foreach ($DNSRecord in $DNSName)
			{
				# Get Reverse DNS Name
				$DNSIPAddress = $DNSRecord.IPAddress
 
				if ($DNSIPAddress -eq $ServerIPAddress)
				{
					$Control = 1;
				}
			}
 
			if ($Control -eq "0")
			{						
				$Output = $ServerIPAddress + ";" + $ServerDNSSubnet + ";" + $ServerDNSName + ";" + $DNSIPAddress
				Add-Content -Value $Output -Path PTRError.txt
				Write-Warning $Output
			}
		}
	}
}