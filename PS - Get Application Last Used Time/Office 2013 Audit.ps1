# Correct filter
$computer = $env:COMPUTERNAME
$namespace = "ROOT\CIMV2"
$classname = "Win32_SoftwareFeature"

Get-WMIObject -Namespace $namespace -Class $classname -ComputerName $computer -ErrorAction SilentlyContinue |

    Where-Object { ($_.ProductName -eq 'Microsoft Office Professional Plus 2013') -and ( $_.Accesses -ge 1 -and $_.LastUse -gt "20160101" -and -not( [int]$_.LastUse.Substring(0,8)-eq "19800000") ) } |
      
    Select-Object Caption, ProductName, Name, @{n='LastUse';e={([System.Management.ManagementDateTimeConverter]::ToDateTime($_.LastUse)).ToString("MM/dd/yyyy")}} #| Format-Table -autosize
    #{[int]($_.Lastuse.Substring(0, 8))}},PSComputername, InstallDate
    
