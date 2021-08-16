[CmdletBinding()]
param (
)

. '.\WizTree Functions.ps1'

# Make sure WizTree is installed.
Test-WizTree

# Run WizTree.
# https://wiztreefree.com/guide#cmdlinecsv
$ArgumentList = '"{0}" /export="{1}" /admin=1 /exportfiles=0' -f "$env:SystemDrive\Users", "$PWD\$WizTreeOutput"
Invoke-WizTree -ArgumentList $ArgumentList

# Define the CSV processing code that is unique to each script.
$ScriptBlock = {

    # Locate user profiles.
    if ( ($FileName -split '\\').Count -eq 4 ) {

        [PSCustomObject]@{
            'Profile' = $FileName
            'Size'    = $Size
        }

    }

}

# Process the CSV.
Read-WizTreeCsv -ScriptBlock $ScriptBlock | Sort-Object -Property 'Size' -Descending