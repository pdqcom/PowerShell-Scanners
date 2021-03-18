
Set-AuthenticodeSignature c"Get WinRM Status.ps1" @(Get-ChildItem cert:\CurrentUser\My -codesigning)[0] -IncludeChain "All" -TimestampServer "http://timestamp.verisign.com/scripts/timstamp.dll"
Get-Ciminstance  -query "select * from cim_datafile where name = 'C:\\Program Files\\Microsoft Office\\Office15\\Outlook.exe' " | select *
Get-Ciminstance  -query "select * from cim_datafile where name = 'C:\\Program Files\\Microsoft Office\\Office15\\Excel.exe' " | Select *
Get-Ciminstance  -query "select * from cim_datafile where name = 'C:\\Program Files\\Microsoft Office\\Office15\\Winword.exe' " | Select *