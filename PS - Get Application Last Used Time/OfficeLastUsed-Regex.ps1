
$Regex = @(
    "Outlook.exe"
    "Winword.exe"
    "Excel.exe"
    "MSAccess.exe"
    "POWERPNT.EXE"
    "FIRSTRUN.exe"
    "MSPUB.EXE"
    "ONENOTE.EXE"
    "OfficeClicktoRun.exe"
     "Firefox.exe"
     "Chrome.exe"
    )

#Get All Executables Listed. Added \z to each entry so we don't get the signature and config files that have the same name.
Get-ChildItem -Path "%ProgramFiles%\*\" -Recurse -ErrorAction SilentlyContinue | Where-Object {$_.LastAccessTime -gt (Get-date).AddDays(-30) -and $_.Name -match ($Regex -join "\z|") + "\z"} | Get-ItemProperty | select name, lastaccesstime