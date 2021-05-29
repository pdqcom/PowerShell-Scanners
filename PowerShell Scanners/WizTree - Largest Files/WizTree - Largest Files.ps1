[CmdletBinding()]
param (
    [UInt32]$Entries = 10,
    [String]$Path = $env:SystemDrive
)

. '.\WizTree Functions.ps1'

# Make sure WizTree is installed.
Test-WizTree

# Run WizTree.
# The output is still sorted by largest folder, even though /exportfolders=0 removes folders from the output.
# I couldn't find a way to get it to sort by largest file. If that was possible, this script would be WAY simpler :)
# https://wiztreefree.com/guide#cmdlinecsv
$ArgumentList = '"{0}" /export="{1}" /admin=1 /sortby=1 /exportfolders=0' -f $Path, "$PWD\$WizTreeOutput"
Invoke-WizTree -ArgumentList $ArgumentList

# Initialize the List that will store the results.
# .Insert() only works if there are already items in the List, so we have to pre-populate it.
$global:LargestFiles = New-Object System.Collections.Generic.List[Object]
for ( $Count = 1; $Count -le $Entries; $Count ++ ) {

    $global:LargestFiles.Add(
        @{
            'FileName' = ''
            'Size'     = 0
        }
    )

}

# Define the CSV processing code that is unique to each script.
$ScriptBlock = {
    
    # FileName can contain a comma, so we have to look for a comma that follows a double quote.
    $FileName, $Remainder = $Reader.ReadLine() -split '",' -replace '"'

    # Grab the size, then discard the rest.
    [UInt64]$Size, $null = $Remainder -split ','

    # Is it larger than the smallest value in the List?
    if ( $Size -gt $global:LargestFiles[-1].Size ) {

        # Check each entry in the List, starting with the largest.
        foreach ( $Index in 0..($global:LargestFiles.Count - 1) ) {

            if ( $Size -gt $global:LargestFiles[$Index].Size ) {

                # Add a new entry to the List above the entry it is larger than.
                Write-Verbose "Index: $Index, Size: $Size, File Name: $FileName"
                $global:LargestFiles.Insert($Index,
                    @{
                        'FileName' = $FileName
                        'Size'     = $Size
                    }
                )

                break

            }
            
        }

        # Keep the List to the maximum number of entries.
        if ( $global:LargestFiles.Count -gt $Entries ) {

            # Remove the last record in the List.
            $global:LargestFiles.RemoveAt($Entries)

        }

    }
    
}

# Process the CSV.
Read-WizTreeCsv -ScriptBlock $ScriptBlock

# Output the results.
foreach ( $Entry in $global:LargestFiles ) {

    [PSCustomObject]$Entry

}