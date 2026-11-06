[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [int]$PacketWaitDuration
)

# Inline module installer for PDQ Connect (no relative path support)
function Install-AndImportModule {
    param (
        [Parameter(Mandatory = $true)]
        [String]$ModuleName
    )
    try {
        $null = Get-InstalledModule $ModuleName -ErrorAction Stop
    } catch {
        if (-not (Get-PackageProvider -ListAvailable | Where-Object Name -eq "Nuget")) {
            $null = Install-PackageProvider "Nuget" -Force
        }
        $null = Install-Module $ModuleName -Force
    }
    $null = Import-Module $ModuleName -Force
}

Install-AndImportModule -ModuleName "PSDiscoveryProtocol"

if ( $PacketWaitDuration ) {
    $CDPPacket = Invoke-DiscoveryProtocolCapture -Type CDP -Duration $PacketWaitDuration -Force
} else {
    $CDPPacket = Invoke-DiscoveryProtocolCapture -Type CDP -Force
}

if ( $CDPPacket ) {
    $Results = Get-DiscoveryProtocolData -Packet $CDPPacket
    if ( $Results ) {
        ForEach ( $Result in $Results ) {
            [PSCustomObject]@{
                "NeighborDeviceName" = $Result.Device
                "NeighborDevicePort" = $Result.Port
                "NeighborDeviceIP"   = $Result.IPAddress[0]
                "LocalInterface"     = $Result.Interface
                "VLAN"               = $Result.VLAN
                "AsOf"               = Get-Date
            }
        }
    } else {
        [PSCustomObject]@{
            "NeighborDeviceName" = "Parsing Error"
            "NeighborDevicePort" = "Parsing Error"
            "NeighborDeviceIP"   = "Parsing Error"
            "LocalInterface"     = "Parsing Error"
            "VLAN"               = "Parsing Error"
            "AsOf"               = Get-Date
        }
    }
} else {
    [PSCustomObject]@{
        "NeighborDeviceName" = "No CDP Packet Received"
        "NeighborDevicePort" = "No CDP Packet Received"
        "NeighborDeviceIP"   = "No CDP Packet Received"
        "LocalInterface"     = "No CDP Packet Received"
        "VLAN"               = "No CDP Packet Received"
        "AsOf"               = Get-Date
    }
}
