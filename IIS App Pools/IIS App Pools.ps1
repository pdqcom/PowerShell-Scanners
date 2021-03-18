if (-Not(Get-Module -ListAvailable -Name iisadministration -ErrorAction SilentlyContinue)) {
    throw "IIS is not installed"
}

import-module iisadministration

$AppPools = Get-IISAppPool

if ($AppPools) {

    ForEach ($AppPool in $AppPools ) {
        [PSCustomObject]@{
            Name = $AppPool.Name
            State = $AppPool.State
        }        
    }
} else {
    Write-Verbose "No app pools were found"
}