$Adobe64 = "c:\windows\system32\macromed\flash\flash*.ocx"
$Adobe32 = "C:\Windows\SysWOW64\Macromed\Flash\flash*.ocx"
 Get-ChildItem $Adobe32 |  Select BaseName, FullName, VersionInfo, *Time  -ErrorAction SilentlyContinue
 Get-ChildItem $Adobe64 |  Select BaseName, FullName, VersionInfo, *Time  -ErrorAction SilentlyContinue

 Get-ChildItem -Path "C:\Windows\SysWOW64\Macromed\Flash\flash*.ocx" |
Get-ItemProperty | select name,lastaccesstime | sort -Property lastaccesstime
