# Instructions
[How to use this repository](../../README.md)

# Description

Calculates how long users were logged in based on audit events.

Requested by [alexhawker](https://old.reddit.com/r/PowerShell/comments/ms4cgm/could_use_some_help_producing_a_list_of_logons/).

Greatly influenced by [User Last Logged On](../User%20Last%20Logged%20On/User%20Last%20Logged%20On.ps1).

# Requirements

* Enable "Audit logon events" in Group Policy.
  * Windows Settings\Security Settings\Local Policies\Audit Policy
* Configure your retention policy to keep the amount of history you want.
  * Administrative Templates\Windows Components\Event Log Service\Security

# Parameters

## Lowercase

Transforms the Username field to lowercase so it groups properly in Inventory. If you don't want this behavior, remove `-Lowercase` from the Parameters field.

# Author
Colby Bouma