Get-WmiObject -Class Win32_Process -Filter "name='Outlook.exe'" | 
  ForEach-Object {
    New-Object -Type PSCustomObject -Property @{
      'Caption'      = $_.Caption
      'CreationDate' = $_.ConvertToDateTime($_.CreationDate)
    }
  }