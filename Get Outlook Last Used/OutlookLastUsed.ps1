 $computer = $env:COMPUTERNAME
$namespace = "ROOT\CIMV2"
$classname = "Win32_SoftwareFeature"

Function Measure-Latest {
    BEGIN { 
        $latest = $null 
    }
    PROCESS {
        if (($_ -ne $null) -and (($latest -eq $null) -or ($_ -gt $latest))) {
            $latest = $_ 
        }
    }
    END {
        $latest
    }
} 

$Software = Get-WmiObject -Class win32_softwarefeature -ComputerName l2dz9433  | Select Caption,@{name="LastUse";
 Expression={$_.ConvertToDateTime($_.LastUse)}}

foreach ($item in $Software) {
    $Name = $Item.Caption
    $LastUsedString = $Item.Lastuse.Substring(0,8)
    $LastUsed = [int]$LastUsedString
    if ($Name -like 'Microsoft Office*' -or $Name -like '*Outlook*') { 
        $LastUsed = $LastUsed | Measure-Latest
            If ($LastUsed -eq "19800000"){
             $LastUsed = "Never"
            }else 
            {#$LastUsed = ([datetime]::parseexact($LastUsed, "yyyyMMdd", [System.Globalization.CultureInfo]::InvariantCulture)).ToString("MM/dd/yyyy")}

            $LastUsed = ([datetime]::parseexact($LastUsed, "yyyyMMdd", [System.Globalization.CultureInfo]::InvariantCulture)).ToString("dd/MM/yyyy")
            
        } 
    }   
}