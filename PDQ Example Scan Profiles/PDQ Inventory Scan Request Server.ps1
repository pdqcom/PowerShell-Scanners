# PDQ Inventory Scan Request Server
# Based on: https://gist.github.com/19WAS85/5424431

[CmdletBinding()]
param (
    [string]$ScanProfile = "Standard",
    [int32]$Port = 8080
)

# HTTP server
$HTTP = [System.Net.HTTPListener]::new() 

# Hostname and port to listen on
$HTTP.Prefixes.Add("http://localhost:$Port/")
$HTTP.Prefixes.Add("http://${Env:ComputerName}:$Port/")
$HTTP.Prefixes.Add("http://${Env:ComputerName}.${Env:UserDNSDomain}:$Port/")

# Start the HTTP Server 
$HTTP.Start()

# Log ready message to terminal 
if ( $HTTP.IsListening ) {

    Write-Verbose "Scan Request Server is running!"

} else {

    Write-Warning "Server did not start, aborting script"
    Exit 10

}



while ($HTTP.IsListening) {

    # The Context object contains all of the request information
    $Context = $HTTP.GetContext()

    # http://YourComputer/ScanRequest/BOB-LAPTOP'
    if ($Context.Request.HTTPMethod -eq 'GET' -and $Context.Request.Url.Segments[1] -eq '/ScanRequest') {
        
        $TargetName = $Context.Request.Url.Segments[2]
        $TargetIP   = $Context.Request.RemoteEndPoint.Address
        
        # Log the IP address of the requester
        Write-Verbose "$TargetIP - $TargetName"

        $Output = PDQInventory.exe ScanComputers -ScanProfile "$ScanProfile" -Computers "$TargetName" 2>&1
        if ( $Output.Exception ) {

            Write-Warning $Output.Exception.Message
            $HTML = $Output.Exception.Message

        } else {

            $HTML = "Scan of $TargetName started successfully"

        }

        # Resposed to the request
        $Buffer = [System.Text.Encoding]::UTF8.GetBytes($HTML)
        $Context.Response.ContentLength64 = $Buffer.Length
        $Context.Response.OutputStream.Write($Buffer, 0, $Buffer.Length) 
        $Context.Response.OutputStream.Close()

    }

    # http://YourComputer/Stop
    if ($Context.Request.HTTPMethod -eq 'GET' -and $Context.Request.RawUrl -eq '/Stop') {

        [string]$HTML = "Stopping server"

        # Resposed to the request
        $Buffer = [System.Text.Encoding]::UTF8.GetBytes($HTML)
        $Context.Response.ContentLength64 = $Buffer.Length
        $Context.Response.OutputStream.Write($Buffer, 0, $Buffer.Length) 
        $Context.Response.OutputStream.Close()
        
        $HTTP.Stop()

    }

}