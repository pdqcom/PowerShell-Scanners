# Created by Colby Bouma
# This script correlates members of a group to their computer from PDQ Inventory
# https://github.com/Sakuru/PDQ_Things/blob/master/AD_Group_to_PDQ_Computer.ps1
# Inspired by http://www.adminarsenal.com/admin-arsenal-blog/using-powershell-and-sqlite/



###############################################################################
## Setup
###############################################################################

# Read parameters from command line
param (
    [string]$Input_Group = $(throw "Group name is required")
)

$PDQ_Database_File = "C:\ProgramData\Admin Arsenal\PDQ Inventory\Database.db"
$SQLite_File = "C:\Program Files (x86)\Admin Arsenal\PDQ Inventory\sqlite3.exe"

# Build the Output object so that the final output is formatted as a table
$Output = New-Object PSObject
$Output | Add-Member User ""
$Output | Add-Member ComputerName ""



###############################################################################
## Main
###############################################################################

# Enumerate members of the group
# -Recursive enumerates members of sub-groups
$Group_Members = Get-ADGroupMember $Input_Group -Recursive

foreach ( $Member in $Group_Members ) {

    $SQL_Query =   "SELECT Name
                    FROM Computers
                    WHERE CurrentUser LIKE '%$($Member.SamAccountName)';"

    # Query the database for any computers that have a matching CurrentUser
    $Output.ComputerName = $(& $SQLite_File $PDQ_Database_File $SQL_Query)
    $Output.User = $($Member.SamAccountName)

    Write-Output $Output

}
