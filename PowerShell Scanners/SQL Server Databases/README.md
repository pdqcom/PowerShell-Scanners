# Instructions
[How to use this repository](../../README.md)

# Description
Returns a list of databases for a given SQL Server instance.
The information includes id, name, compatibility level, creation date, owner, collation and status.
System databases are excluded.

# Requirements
Internally the script uses sqlcmd.exe.

# Parameters
## Instance
The SQL instance to connect to. Default is ".\SQLExpress".

# Author
Petar Georgiev