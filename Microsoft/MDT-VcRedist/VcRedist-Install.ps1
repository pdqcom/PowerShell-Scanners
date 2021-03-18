Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)
$LogPS = "${env:SystemRoot}" + "\Temp\VcRedist Install MDTBuildLab Bundle PS Wrapper.log"
Start-Transcript $LogPS

$temp = "C:\Windows\Temp\VcRedist"
$MdtPath = "C:\MDTBuildLab"

Write-Verbose "Install/Update VcRedist Module" -Verbose
Install-Module -Name VcRedist -Force
Import-Module -Name VcRedist

Write-Verbose "Get VcRedist List" -Verbose
$VcList = Get-VcList

Write-Verbose "Save all VcRedist setup files to $temp"
If (!(Test-Path -Path $temp)) { New-Item -Path $temp -ItemType Directory -Force }
Save-VcRedist -Path $temp -VcList $VcList

Write-Verbose "Import applications and create bundle"
Import-VcMdtApplication -VcList $VcList -Path $temp -MdtPath $MdtPath
New-VcMdtBundle -MdtPath $MdtPath

Write-Verbose "Clean up $temp"
Remove-Item $temp -Recurse -Force

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
