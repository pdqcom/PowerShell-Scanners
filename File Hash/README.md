# Instructions
[How to use this repository](../../README.md)

# Description
Runs `Get-FileHash` on files in a directory to calculate their hash values

# Parameters
* `-Path` The directory to search
* `-Filter` A Qualifier for the Path parameter. Supports wildcards like * and ?.
* `-Recurse` Whether to search the path recursively
* `-Algorithm` Hash algorithm to use. Defaults to **SHA256** and supports SHA1, SHA256, SHA384, SHA512, and MD5.

## Example Parameters
	-Path "C:\Windows" -Filter "*.txt" -Algorithm MD5 -Recurse

# Author
Bryan Mason