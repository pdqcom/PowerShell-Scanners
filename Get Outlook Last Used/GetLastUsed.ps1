#Executable Fullnames
$Regex = @(
    "Outlook.exe"
    "Winword.exe"
    "Excel.exe"
    "MSAccess.exe"
    "POWERPNT.EXE"
    "MSPUB.EXE"
    "ONENOTE.EXE"
    )

#Get All Executables Listed. Added \z to each entry so we don't get the signature and config files that have the same name.
Get-ChildItem -Path "C:\Program Files*\" -Recurse -ErrorAction SilentlyContinue | Where-Object {$_.Name -match ($Regex -join "\z|") + "\z"} | Get-ItemProperty | select name, lastaccesstime