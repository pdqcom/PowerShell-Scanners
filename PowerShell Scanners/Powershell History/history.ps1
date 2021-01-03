$user = (Get-WmiObject -Class Win32_Process -Filter 'Name="explorer.exe"').GetOwner().User
$history =  Get-Content "C:\Users\$user\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt"
[array]::Reverse($history)
$commandarray =  New-Object System.Collections.ArrayList

foreach($command in $history){
    if($commandarray -notcontains $command){
        [void]$commandarray.Add($command)
        [PSCustomObject]@{
            User = $user
            Host = $env:COMPUTERNAME
            Command = $command
        }
    }

}
