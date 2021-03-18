#$_.ConvertToDateTime($_.CreationDate)
$result = @();
$soft = @{};
$pc = $env:COMPUTERNAME
Get-WmiObject -Namespace ROOT\CIMV2 -Class Win32_SoftwareFeature -Computer $pc |
Select-Object PSComputerName, ProductName, LastUse -unique |
Sort-Object ProductName, LastUse |
Where-Object -FilterScript {$_.ProductName -like "Microsoft Office Professional*"} |
ForEach-Object { $soft[$_.ProductName] = $_.LastUse };
$soft.Keys |
ForEach-Object { $dt = [datetime]::parseexact($soft[$_].Substring(0,8),"yyyyMMdd",[System.Globalization.CultureInfo]::InvariantCulture); if ($dt -lt (Get-Date).AddDays(-60)) { $line = "" | select ComputerName,ProductName,LastUsed; $line.ComputerName = $comp; $line.ProductName = $_; $line.LastUsed = $dt; $result += $line } };
$result |
Sort-Object ComputerName, ProductName, LastUsed |
Format-table -autosize;