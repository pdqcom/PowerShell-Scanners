$LogName = 'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'
$Results = New-Object System.Collections.ArrayList
$logs = Get-WinEvent -LogName $LogName
$UserArray = New-Object System.Collections.ArrayList

#Parse WinEvent log for info
foreach ($log in $logs) {
         $logXml = [xml]$log.ToXML()

         #Hash table for RDP data
         $ResultHash = @{
             Time        = $log.TimeCreated.ToString()
             'Event ID'  = $log.Id
             'Desc'      = ($log.Message -split "`n")[0]
             Username    = $logXml.Event.UserData.EventXML.User   
             'Source IP' = $logXml.Event.UserData.EventXML.Address
             'Details'   = $log.Message
         }
    
         [void]$Results.Add((New-Object PSObject -Property $ResultHash))
         
     }

    foreach ($result in $Results) {
        if (($result.'Event ID' -eq 24) -and ( $result.Username -notmatch "^(DWM|UMFD)-\d" )) {
            
        if ( $UserArray -notcontains $result.Username ) {
            [void]$UserArray.Add($result.Username)
            [PSCustomObject]@{
                Username  = $result.Username
                LogonType = "RDP"
                LastLogoff = $result.Time
                SourceIP = $result.'Source IP'
                Description = $result.'Desc'
                Details = $result.'Details'
            } 
        }
    }
}