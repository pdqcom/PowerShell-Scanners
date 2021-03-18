<#Get-WmiObject -Class win32_softwarefeature  |

    Where-Object {$_.Caption -match 'Microsoft\sOffice|Microsoft\sOutlook|Microsoft\sExcel|Microsoft\sWord' -and -not( [int]$_.LastUse.Substring(0,8)-eq "19800000")} |
      
    Select-Object Caption, ProductName, Name, @{n='LastUse';e={[int]($_.Lastuse.Substring(0, 8))}},PSComputername, InstallDate
    #>
Get-wmiobject -Class Win32_SoftwareFeature -Filter "name = 'OutlookFiles' or name = 'ExcelFiles' or name = 'AccessFiles' or name = 'WordFiles'" -ErrorAction SilentlyContinue| 
  ForEach-Object {
    New-Object -Type PSCustomObject -Property @{
      'Caption'      = $_.Caption
      'LastUsed' = [System.Management.ManagementDateTimeConverter]::ToDateTime($_.LastUse)

    }
  }