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
                "Switch" = $Result.Device
                "SwitchPort" = $Result.Port
                "SwitchIP" = $Result.IPAddress[0]
                "LocalInterface" = $Result.Interface
                "VLAN" = $Result.VLAN
                "AsOf" = Get-Date
            }
        }
    } else {
        [PSCustomObject]@{
            "Switch" = "Parsing Error"
            "SwitchPort" = "Parsing Error"
            "SwitchIP" = "Parsing Error"
            "LocalInterface" = "Parsing Error"
            "VLAN" = "Parsing Error"
            "AsOf" = Get-Date
        }
    }
} else {
    [PSCustomObject]@{
        "Switch" = "No CDP Packet Received"
        "SwitchPort" = "No CDP Packet Received"
        "SwitchIP" = "No CDP Packet Received"
        "LocalInterface" = "No CDP Packet Received"
        "VLAN" = "No CDP Packet Received"
        "AsOf" = Get-Date
    }
}
