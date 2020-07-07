#Get the contents of the hosts file
$HostFile = Get-Content -Path "C:\Windows\System32\drivers\etc\hosts"

#Iterate through each line to return the IP Address, Hostname, and Comments for each entry
foreach($line in $HostFile){

    #skip commented lines and empty lines in the file
    if($line -like '#*' -or $line -eq ''){continue}

    #Split the entry by whitespace to target the fields independently
    $entrytext = $line.ToString().Trim()
    [System.Collections.ArrayList]$entryArray = $entrytext -split "\s+"
    
    #Assign IPAddress and HostName
    $IPAddress = $entryArray[0]
    $HostName = $entryArray[1]
    
    #Avoid incomplete entries
    if ( $entryArray.Count -ge 2 ) {
    
        #Remove the $IPAddress and $HostName from the $entryArray
        $entryArray.RemoveRange(0,2)
        
        #Convert $entryArray back to a string for the Comments field
        $Comments = [string]$entryArray

    }

    #Return host file entry
    [PSCustomObject]@{
        IPAddress = $IPAddress
        HostName = $HostName
        Comments = $Comments
    }
}
