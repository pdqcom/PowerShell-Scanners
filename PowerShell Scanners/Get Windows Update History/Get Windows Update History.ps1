& '.\Install and Import Module.ps1' -ModuleName "PSWindowsUpdate"

# Retrieve the Row Limit from a log file.
$RowLimit = [Int32](Get-Content .\Scanner.log | Select-String 'First = (\d+)').Matches.Groups[1].Value

# -Last limits the number of results. This is necessary in Windows 10 2004 and later.
# https://github.com/pdq/PowerShell-Scanners/issues/74
Get-WUHistory -Last $RowLimit