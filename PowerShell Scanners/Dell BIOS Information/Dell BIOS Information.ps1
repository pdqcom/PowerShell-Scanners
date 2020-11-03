IF (Get-WmiObject -Class:Win32_ComputerSystem -Filter:"Manufacturer LIKE '%Dell%'"){
$null = Install-Module DellBIOSProvider -force
$null = Import-Module DellBIOSProvider -force
Get-ChildItem dellsmbios:\ | ForEach-Object {
$Category = $_.Category
Get-ChildItem dellsmbios:\"$Category" | ForEach-Object {
[PSCustomObject]@{
Category = $Category
Attribute = $_.Attribute
Description = $_.Description
CurrentValue = $_.CurrentValue
}
} 
}
}