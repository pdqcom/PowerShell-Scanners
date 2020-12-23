$LogName = 'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'
$Results = @()
$Events = Get-WinEvent -LogName $LogName
$UserArray = New-Object System.Collections.ArrayList

#Parse WinEvent log for info
foreach ($Event in $Events) {
         $EventXml = [xml]$Event.ToXML()

         #Hash table for RDP data
         $ResultHash = @{
             Time        = $Event.TimeCreated.ToString()
             'Event ID'  = $Event.Id
             'Desc'      = ($Event.Message -split "`n")[0]
             Username    = $EventXml.Event.UserData.EventXML.User   
             'Source IP' = $EventXml.Event.UserData.EventXML.Address
             'Details'   = $Event.Message
         }
    
         $Results += (New-Object PSObject -Property $ResultHash)
         
     }

    foreach ($result in $Results) {
        if (($result.'Event ID' -eq 24) -and ( $result.Username -notmatch "^(DWM|UMFD)-\d" )) {
            
        if ( $UserArray -notcontains $result.Username ) {
            $UserArray += $result.Username
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