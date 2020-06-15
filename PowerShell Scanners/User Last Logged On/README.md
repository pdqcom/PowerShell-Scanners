# Instructions
[How to use this repository](../../README.md)

# Description

Queries the Security Event Log to determine the last time each user logged on to the target machine.

# Requirements

* Enable "Audit logon events" in Group Policy
  * Windows Settings\Security Settings\Local Policies\Audit Policy
* Configure your retention policy to keep the amount of history you want
  * Administrative Templates\Windows Components\Event Log Service\Security

# Parameters

## Lowercase

Transforms the Username field to lowercase so it groups properly in Inventory. If you don't want this behavior, remove `-Lowercase` from the Parameters field.

# Author
Nate Blevins