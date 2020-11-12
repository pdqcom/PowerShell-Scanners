# Instructions
[How to use this repository](../../README.md)

# Description

Uses a registry key to determine the last logged in user then
uses system.DirectoryServices.DirectorySearcher to 
find active directory groups that user is associated with.

Returns the following Group Information:
* DistinguishedName 
* GroupCategory
* GroupScope
* Name
* SamAccountName
* mail

# Author  
Matt Henry
