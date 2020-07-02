# Instructions
[How to use this repository](../../README.md)

# Description
Reads the extensions JSON file of each user on the system to determine which extensions each user has installed.

Based on this script by Jerry Lord: https://help.pdq.com/hc/en-us/community/posts/360050799132-Firefox-extension-inventory

# Parameters
## EnablePermissions
Enables the Permissions field. I disabled this by default because it's a multi-line string that is pretty ugly in Inventory.

## EnableDefaultExtensions
Default extensions are discarded by default. This parameter allows you keep them.

# Authors
* Jerry Lord
* Colby Bouma