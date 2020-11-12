# Instructions
[How to use this repository](../../README.md)

# Description

Uses a registry key to determine the last logged in user.
Uses system.DirectoryServices.DirectorySearcher to then
find active directory groups that user is associated with.

Returns the following:  
* User
    * Last Logged in User
* Group
    * DistinguishedName 
    * GroupCategory
    * GroupScope
    * Name
    * SamAccountName
    * mail

# Author  
Matt Henry
