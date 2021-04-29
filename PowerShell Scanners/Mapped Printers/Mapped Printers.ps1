$Printers = Get-WMIObject Win32_Printer | where{$_.Name -like "*\\*"}
$default = Get-WMIObject -Query " SELECT * FROM Win32_Printer WHERE Default=$true" | where{$_.Name -like "*\\*"}

if ( $Printers ) {

    ForEach ( $Printer in $Printers ) {
        if ( $Printer.sharename -eq $default.ShareName) {

            [PSCustomObject]@{
                Sharename           = $Printer.sharename
                Name                = $Printer.name
                Default             = "True"
            }
        }
        else {

            [PSCustomObject]@{
                Sharename           = $Printer.sharename
                Name                = $Printer.name
                Default             = "False"
            }
        }

    }

} else {

    Write-Verbose "No mapped printers were found"

}