#Get the contents of the hosts file
$HostFile = Get-Content -Path "C:\Windows\System32\drivers\etc\hosts"

#Add valid host entries into an arraylist
#Collect the IP address, hostname, and comments
[System.Collections.ArrayList]$HostsFileEntries = @()
foreach($line in $HostFile){

    #skip commented lines and empty lines in the file
    if($line -like '#*' -or $line -eq ''){continue}

    #Split the entry by whitespace to target the fields independently
    $entrytext = $line.ToString().Trim()
    [System.Collections.ArrayList]$entryArray = $entrytext -split "\s+"
    $IPAddress = $entryArray[0]
    $HostName = $entryArray[1]
    #Remove the $IPAddress and $HostName from the $entryArray
    $entryArray.RemoveRange(0,2)
    #Convert $entryArray back to a string for the comments entry
    $Comments = [string]$entryArray

    #Add host file entry to custom object
    $obj = [PSCustomObject]@{
        IPAddress = $IPAddress
        HostName = $HostName
        Comments = $Comments
    }
    $HostsFileEntries.Add($obj) | Out-Null
}
return $HostsFileEntries