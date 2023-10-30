# Instructions
[How to use this repository](../../README.md)

# Description
Imports the excellent PSDiscoveryProtocol module (https://github.com/lahell/PSDiscoveryProtocol) from the current folder, then listens for a CDP packet for 62 seconds, and if one is received, parses it and returns the contents.

# Requirements
All files are present in this folder. Network equipment has to send CDP packets out and the devices running this script must be allowed to receive them.

# Parameters
## PacketWaitDuration
(Optional) How long the scanner should wait for a CDP packet. Default is 62 seconds.

# Author
Jonas M. Hunziker