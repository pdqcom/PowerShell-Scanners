param (
    [string]$Path = "$env:userprofile", 
    [string]$Filter,
    [switch]$Recurse,
    [string]$Algorithm ="SHA256")

$Files = Get-ChildItem -File -Path $Path -Filter $Filter -Recurse:$Recurse

ForEach ( $File in $Files ) {

    [PSCustomObject]@{
        Name = $File.Name
        Path = $File.FullName        
        Hash = (Get-FileHash $File.PSPath -Algorithm $Algorithm).Hash
    }
}
