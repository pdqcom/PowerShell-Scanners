Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$MyConfigFileloc = ("${env:Settings}\Applications\Settings.xml")
[xml]$MyConfigFile = (Get-Content $MyConfigFileLoc)

$SetupUser = $MyConfigFile.Settings.Microsoft.SetupUser
$SetupPassword = $MyConfigFile.Settings.Microsoft.SetupPassword
$SetupPassword = $SetupPassword | ConvertTo-SecureString -asPlainText -Force
$Setup_CredObject = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $SetupUser, $SetupPassword

$Vendor = "PDQ"
$Product = "MDT Evergreen Nested Package"
$PackageName = "pdqdeploy"
$Version = "1.0"
$InstallerType = "exe"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$pdqserver = "mdt"
$pdqnestedpackage = "WS2016-002"
$ip = $(Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet0).IPAddress

Start-Transcript $LogPS

Write-Verbose "Starting Installation of $Vendor $Product $Version" -Verbose
Invoke-Command -ComputerName $pdqserver -Credential $Setup_CredObject -ScriptBlock { pdqdeploy.exe Deploy -Package "$pdqnestedpackage" -Targets $args[0] } -Args $ip 2>&1
Start-Sleep 30
Write-Verbose "Wait for PDQ to finish" -Verbose
while (Test-Path "C:\Windows\AdminArsenal\PDQDeployRunner\service-1.lock") { Start-Sleep 30 }

Write-Verbose "Customization" -Verbose

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
