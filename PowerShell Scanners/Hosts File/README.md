# Instructions
[How to use this repository](../../README.md)

# Description
Parses the hosts file and outputs a formatted list of entries. Hosts file lines that have multiple hostnames will be displayed as multiple lines with the same IP address.

Example with `-ShowDisabled`:

```
1.2.3.4 example.com www.example.com
2.3.4.5 beer.example.com #Wine too!
#3.4.5.6 it.crowd #I'm disabled.
```

HostName | IPAddress | Enabled | Comments
-------- | --------- | ------ | --------
example.com | 1.2.3.4 | True |
www.example.com | 1.2.3.4 | True |
beer.example.com | 2.3.4.5 | True | Wine too!
it.crowd | 3.4.5.6 | False | I'm disabled.

# Parameters
## ShowDisabled
Adds disabled lines to the output. A disabled line is one that starts with `#`, but otherwise contains a valid entry. The `Enabled` field is used to distinguish between enabled and disabled lines.

## Verbose
Add additional information to the Output Log.

# Author
Colby Bouma