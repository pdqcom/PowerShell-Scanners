#$ComputerNames = Get-Content  "C:\Users\Charles.Bailey\Work Folders\Projects\computers.txt"
#Invoke-Command -ComputerName $ComputerNames -Authentication Negotiate -ScriptBlock
$os = Get-CimInstance -ClassName Win32_ComputerSystem
$pc = $env:COMPUTERNAME
$now = $currenttime
$LastUsedDate=@();

Get-CimInstance -Class win32_softwarefeature -ComputerName $pc -ErrorAction SilentlyContinue | # |
    Where-Object { $_.Accesses -gt 500 -and $_.Name -like 'Outlook%'} |
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
            LastUsedDate = $_.LastUse.ToString("yyyymmddHHMMSS.mmmmmmsUUU") #[System.Management.ManagementDateTimeConverter]::ToDateTime($os.Lastuse) #LastUse.ToStirng("MM/dd/yyyy"))
        }
    }