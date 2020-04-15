# Requirements
* [One True Brace Style (OTBS)](https://github.com/PoshCode/PowerShellPracticeAndStyle/blob/master/Style-Guide/Code-Layout-and-Formatting.md#one-true-brace-style)
* No aliases (GCI, ?, %, etc.)
* Meaningful variable names (not \$A, \$Var1, etc.)
* Indentation. IDEs like Visual Studio Code will help you with this.

# Recommendations
### ArrayList instead of arrays
Using an ArrayList is a lot faster than regular arrays, especially when you're dealing with a lot of data. https://foxdeploy.com/2016/03/23/coding-for-speed/

Use this:
```PowerShell
$MyArray = New-Object System.Collections.ArrayList
For ( $Count = 1; $Count -le 10000000; $Count ++ ) {
    $null = $MyArray.Add($Count)
}
```

or this:
```PowerShell
$MyArray = New-Object System.Collections.Generic.List[UInt32]
For ( $Count = 1; $Count -le 10000000; $Count ++ ) {
    $MyArray.Add($Count)
}
```

instead of this:
```PowerShell
$MyArray = @()
For ( $Count = 1; $Count -le 10000000; $Count ++ ) {
    $MyArray += $Count
}
```

### Do not compare to $null
Using $null comparisons can have [strange unwanted consequences](https://github.com/PowerShell/PSScriptAnalyzer/blob/development/RuleDocumentation/PossibleIncorrectComparisonWithNull.md). It's usually best to avoid it altogether.

Use this:
```PowerShell
$Drives = Get-ItemProperty "Registry::HKEY_USERS\*\Network\*"
if ( $Drives ) {
    Do-FancyThings
}
```

instead of this:
```PowerShell
$Drives = Get-ItemProperty "Registry::HKEY_USERS\*\Network\*"
if ( $Drives -ne $null ) {
    Do-FancyThings
}
```

### Use functions for reused code
If you find yourself copying and pasting a chunk of your code with only minor changes, you should probably use a function instead.

Use this:
```PowerShell
function Download-File {
    param (
        [String]$FileName
    )

    if ( -Not ( Test-Path $FileName ) ) {
        Invoke-RestMethod "https://mywebsite.tld/$FileName"
    }
}

Download-File -FileName "File1.exe"
Download-File -FileName "File2.exe"
```

instead of this:
```PowerShell
if ( -Not ( Test-Path "File1.exe" ) ) {
    Invoke-RestMethod "https://mywebsite.tld/File1.exe"
}
if ( -Not ( Test-Path "File2.exe" ) ) {
    Invoke-RestMethod "https://mywebsite.tld/File2.exe"
}
```

# Use "$null =" to erase output
It's faster than `Out-Null`, which probably doesn't matter for most scripts, but why not go with the faster option? :)

Use this:
```PowerShell
$null = Install-Module -Name "FancyPants" -Force
```

instead of this:
```PowerShell
Install-Module -Name "FancyPants" -Force | Out-Null
```