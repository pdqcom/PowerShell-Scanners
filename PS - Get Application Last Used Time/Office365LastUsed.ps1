##Get Last Access Time of Executable

Get-ChildItem -Path "C:\Program Files\Microsoft Office\root\Office16" -Filter "Excel.exe" -ErrorAction SilentlyContinue  | Get-ItemProperty | Select name, lastaccesstime
Get-ChildItem -Path "C:\Program Files\Microsoft Office\root\Office16" -Filter "Outlook.exe" -ErrorAction SilentlyContinue | Get-ItemProperty  | Select name, lastaccesstime 
Get-ChildItem -Path "C:\Program Files\Microsoft Office\root\Office16" -Filter "POWERPNT.EXE" -ErrorAction SilentlyContinue  | Get-ItemProperty  |  Select name, lastaccesstime
Get-ChildItem -Path "C:\Program Files\Microsoft Office\root\Office16" -Filter "ONENOTE.EXE" -ErrorAction SilentlyContinue | Get-ItemProperty  | Select name, lastaccesstime  
Get-ChildItem -Path "C:\Program Files\Microsoft Office\root\Office16" -Filter "MSPUB.EXE" -ErrorAction SilentlyContinue  | Get-ItemProperty  | Select name, lastaccesstime  
Get-ChildItem -Path "C:\Program Files\Microsoft Office\root\Office16" -Filter "WINWORD.EXE" -ErrorAction SilentlyContinue | Get-ItemProperty  | Select name, lastaccesstime  
Get-ChildItem -Path "C:\Program Files\Microsoft Office\root\Office16" -Filter "MSACCESS.EXE" -ErrorAction SilentlyContinue | Get-ItemProperty  | Select name, lastaccesstime   