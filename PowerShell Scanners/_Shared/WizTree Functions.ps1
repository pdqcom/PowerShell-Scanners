$WizTreePath = "$env:ProgramFiles\WizTree\WizTree.exe"
$WizTreeOutput = 'WizTree.csv'

function Test-WizTree {

    [CmdletBinding()]
    param (
    )

    if ( -not (Test-Path $WizTreePath) ) {

        Write-Verbose "WizTree path: $WizTreePath"
        throw 'Unable to find WizTree. Please make sure it is installed.'

    }

}

function Invoke-WizTree {

    [CmdletBinding()]
    param (
        [String]$ArgumentList
    )

    $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
    Start-Process -Wait -FilePath $WizTreePath -ArgumentList $ArgumentList
    $StopWatch.Stop()

    Write-Verbose "WizTree took $([Math]::Round($StopWatch.Elapsed.TotalSeconds, 1)) seconds."

}

function Read-WizTreeCsv {

    [CmdletBinding()]
    param (
        [ScriptBlock]$ScriptBlock,
        [Switch]$Initialized
    )

    if ( -not $Initialized ) {

        # I initially used .Invoke() to run the scriptblock, but polymorphic code is much faster >:D
        # Thanks for the inspiration, Kris!
        # https://www.pdq.com/blog/viewing-powershell-function-contents/#method-2-using-function
        # I had to make the pattern different than the target it's searching for, so I added a + after the #.
        # This works because -replace uses regex, so I'm telling -replace to search for 1 or more #.
        ${Function:Read-WizTreeCsv} = ${Function:Read-WizTreeCsv} -replace '#+Initialize', $ScriptBlock

        # From my testing, I determined that this recursive call is necessary.
        # PowerShell got stuck when I tried to make it keep executing the same function after it had changed itself.
        Read-WizTreeCsv -Initialized -ScriptBlock $ScriptBlock

    } else {

        # Read the CSV 1 line at a time with StreamReader.
        # Get-Content uses too much RAM, and ConvertFrom-Csv is too slow.
        # I expect some CSVs could have millions of lines.
        $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
        $Reader = New-Object -TypeName System.IO.StreamReader -ArgumentList (Get-Item $WizTreeOutput)

        # Skip the donation message and headers.
        $LineCount = 1
        if ( $Reader.ReadLine().StartsWith('Generated') ) {
    
            $null = $Reader.ReadLine()
            $LineCount ++

        }

        do {
    
            # FileName can contain a comma, so we have to look for a comma that follows a double quote.
            $FileName, $Remainder = $Reader.ReadLine() -split '",' -replace '"'

            # Grab the size, then discard the rest.
            [UInt64]$Size, $null = $Remainder -split ','

            #Initialize
            
            $LineCount ++
    
        } until ( $Reader.EndOfStream )

        $StopWatch.Stop()
        Write-Verbose "CSV contains $LineCount lines."
        Write-Verbose "CSV processing took $([Math]::Round($StopWatch.Elapsed.TotalSeconds, 1)) seconds."

        $Reader.Close()

    }

}