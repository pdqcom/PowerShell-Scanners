Get-wmiobject -Class Win32_Process -Filter "name='Outlook.exe' or name='Excel.exe' or name='winword.exe' or name='msaccess.exe'" | 
  ForEach-Object {
    New-Object -Type PSCustomObject -Property @{
      'Caption'      = $_.Caption
      'CreationDate' = $_.ConvertToDateTime($_.CreationDate)
    }
  }