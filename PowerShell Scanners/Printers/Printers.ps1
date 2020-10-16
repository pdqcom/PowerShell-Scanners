
param(
    [Switch]$NoNetworkPrinters = $false,
    [Switch]$NoLocalPrinters = $false
)
# $NoNetworkPrinters = $true
# $NoLocalPrinters = $true

# 'Local' is not an existing Property but this adds it for us so we can use it later
$printers = Get-CimInstance Win32_Printer | Select-Object -Property Name, ShareName, Location, PrinterStatus, SystemName, Shared, Local


if ($printers) {
    # https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-printer
    # PrinterStatus starts at 1 so we add a 'NULL' entry for simplicity's sake
    $status = "NULL", "Other", "Unknown", "Idle", "Printing", "Warmup", "Stopped Printing", "Offline"

    # Filter out printers based on input switches, decide if printer is local or networked, pretty up the PrinterStatus
    $result = [System.Collections.ArrayList] @()
    foreach ($printer in $printers) {

        # Check if the SystemName doesn't start with \\
        # SystemName starting with indicates that it is coming from a UNC path
        $printer.Local = $printer.SystemName -match "^(?!\\)"

        if ($NoNetworkPrinters -and -not $printer.Local) {
            # Don't add it
        }
        elseif ($NoLocalPrinters -and $printer.Local) {
            # Don't add it
        }
        else {
            $result.Add($printer) 1> $null
        }

        # Convert the PrinterStatus to String
        $printer.PrinterStatus = $status[$printer.PrinterStatus]
    }

    $result | Select-Object -Property Name, ShareName, Location, Shared, Local, PrinterStatus

}