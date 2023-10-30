[CmdletBinding()]
param (
	[Parameter(Mandatory=$false)][int]$PacketWaitDuration
)
Import-Module '.\PSDiscoveryProtocol.psm1'
if($PacketWaitDuration){
    $CDPPacket = Invoke-DiscoveryProtocolCapture -Type CDP -Duration $PacketWaitDuration    
} else {
    $CDPPacket = Invoke-DiscoveryProtocolCapture -Type CDP
}
if($CDPPacket) {
    $Results = Get-DiscoveryProtocolData -Packet $CDPPacket
    If($Results) {
        ForEach($Result in $Results){
            [PSCustomObject]@{
                "NeighborDeviceName" = $Result.Device
                "NeighborDevicePort" = $Result.Port
                "NeighborDeviceIP" = $Result.IPAddress[0]
                "LocalInterface" = $Result.Interface
                "VLAN" = $Result.VLAN
                "AsOf" = Get-Date
            }
        }
    } else {
        [PSCustomObject]@{
            "NeighborDeviceName" = "Parsing Error"
            "NeighborDevicePort" = "Parsing Error"
            "NeighborDeviceIP" = "Parsing Error"
            "LocalInterface" = "Parsing Error"
            "VLAN" = "Parsing Error"
            "AsOf" = Get-Date
        }
    }
} else {
    [PSCustomObject]@{
        "NeighborDeviceName" = "No CDP Packet Received"
        "NeighborDevicePort" = "No CDP Packet Received"
        "NeighborDeviceIP" = "No CDP Packet Received"
        "LocalInterface" = "No CDP Packet Received"
        "VLAN" = "No CDP Packet Received"
        "AsOf" = Get-Date
    }
}
