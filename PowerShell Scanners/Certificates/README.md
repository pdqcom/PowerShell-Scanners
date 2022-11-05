# Instructions
[How to use this repository](../../README.md)

# Description
Lists certificates from the `Cert:` PSDrive. You can filter the results with the parameters that are detailed below.

# Requirements
You may want to change the Scan As setting to `Logged on User` for this Scan Profile.

# Parameters
## Property
A comma-separated list of fields you would like this scanner to return. The available fields are listed at the top of Certificates.ps1.

## StoreLocation
Allows you to filter results to just CurrentUser or LocalMachine. Defaults to returning both.

## StoreName
Allows you to filter results to just the stores you want. I didn't include a list because I suspect some environments
may have more stores than others.

To find available stores, run:

```powershell
(Get-ChildItem -Path 'Cert:\CurrentUser').Name | Sort-Object
(Get-ChildItem -Path 'Cert:\LocalMachine').Name | Sort-Object
```

# Author
Colby Bouma