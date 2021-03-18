# https://www.pdq.com/blog/get-appxpackages/

if (-Not(Get-Command Get-AppxPackage -ErrorAction SilentlyContinue)) {
    throw "Get-AppxPackage does not exist here, I bet if you look at the machine closely you will see that it is not windows 10"
}

##Get Online Provisioned Packages
$Packages = Get-AppxPackage

##Create Your Whitelist
$Whitelist = @(
    '*WindowsCalculator*',
    '*MSPaint*',
    '*Office.OneNote*',
    '*Microsoft.net*',
    '*MicrosoftEdge*'
)

##Remove all Applications in your whitelist
ForEach($App in $Packages){
    $Matched = $false
    Foreach($Item in $Whitelist){
        If($App -like $Item){
            $Matched = $true
            break
        }
    }
    if($matched -eq $false){
        [PSCustomObject]@{
        Name    = $App.Name
        Location    = $App.InstallLocation
        }
    }
}