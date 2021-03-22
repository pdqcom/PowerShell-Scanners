# Instructions
[How to use this repository](../../README.md)

# Description
Grabs neighbor cache entries, commonly called the ARP cache in IPV4, and attempts to get a reverse DNS lookup and NetBIOS name for each.

# Parameters
## AddNbtName
Attempts to get the NetBIOS name of each neighbor cache entry by parsing the results of nbtstat -A

## AddReverseLookup
Attempts to do a reverse DNS lookup on the IP Address of each neighbor cache entry.

# Authors
* Andrew Pla