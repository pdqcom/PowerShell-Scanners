# Instructions
[How to use this repository](../../README.md)

# Description
Reads the Preferences JSON file of each user on the system to determine which extensions each user has installed.

Based on this script by Jerry Lord: https://help.pdq.com/hc/en-us/community/posts/360050592031-chrome-extension-inventory

# Parameters
## Verbose
Enables Verbose log messages. If you don't want Verbose messages in your Output Log, remove `-Verbose` from the Parameters field.

## EnablePermissions
Enables the Permissions field. I disabled this by default because it's a multi-line string that is pretty ugly in Inventory.

# Authors
* Jerry Lord
* Colby Bouma