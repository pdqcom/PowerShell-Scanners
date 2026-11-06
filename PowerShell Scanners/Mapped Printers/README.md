# Mapped Printers

## Instructions

[How to use this repository](../../README.md)

## Description

This scanner query wmi and looks for default printer and mapped printers

## Compatibility

* **PDQ Inventory**: Yes
* **PDQ Connect**: Only when run as the logged on user. Printer connections are per-user, so this will not find mapped printers when run as SYSTEM.

## Parameters

### Verbose

Enables Verbose log messages. If you don't want Verbose messages in your Output Log, remove `-Verbose` from the Parameters field.

## Author

Jochemin thanks to Colby Bouma
