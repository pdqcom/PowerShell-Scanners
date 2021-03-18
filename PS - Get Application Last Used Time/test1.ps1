#$ComputerNames = Get-Content  "C:\Users\Charles.Bailey\Work Folders\Projects\computers.txt"
#Invoke-Command -ComputerName $ComputerNames -Authentication Negotiate -ScriptBlock
$os = Get-CimInstance -ClassName Win32_ComputerSystem
$pc = $env:COMPUTERNAME
$now = $currenttime
Get-CimInstance -Class win32_softwarefeature -ComputerName $pc #$ComputerNames  | # |
    Where-Object { $_.LastUse -ne '19800000******.000000+***",,48'} |
    Select-Object Caption, PSComputername |
    Group-Object PSComputername |
    ForEach-Object {
        $Group = $_.Group |
            Sort-Object LastUse 
           # Select-Object -Last 1
        [PSCustomObject]@{
            ComputerName = $_.Name
            ProductName = $_.ProductName
            Caption = $Group.Caption
            LastUse = $_.LastUse.ToString("yyyymmddHHMMSS.mmmmmmsUUU") #[System.Management.ManagementDateTimeConverter]::ToDateTime($os.Lastuse) #LastUse.ToStirng("MM/dd/yyyy"))
        }
    }