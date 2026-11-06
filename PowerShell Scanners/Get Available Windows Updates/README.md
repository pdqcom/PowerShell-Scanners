# Get Available Windows Updates

## Instructions

[How to use this repository](../../README.md)

## Description

Installs the PSWindowsUpdate module, then runs Get-WindowsUpdate. This returns all updates that are currently available.

## Compatibility

* **PDQ Inventory**: Yes
* **PDQ Connect**: No, working on a version that does

## Parameters

### WSUS

Specify to check WSUS for updates. The target must be configured to use a WSUS server.

If this is not specified, the scanner uses whichever update service the target is configured to use.

## Author

Colby Bouma
