if(Get-CimInstance -ClassName Win32_ComputerSystem | Where Manufacturer -like 'Dell*')
 {
    $LASTEXITCODE = 55
    Write("You have an error")
   # $name = read-host "Enter computer name "
$msg = "Your computer is about to update"
Invoke-WmiMethod -Path Win32_Process -Nam.e Create -ArgumentList "msg * $msg" -ComputerName $name
 }else
 {
    $LASTEXITCODE = 60
    }