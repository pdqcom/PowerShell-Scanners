[CmdletBinding()]
param (
    # Number of days worth of entries to collect
    [UInt32]$Days = 28, # Defaults to Four weeks
    # Limit the number of returned events
    [UInt32]$EventLimit = 30, # Defaults to 30 events
    [ValidateSet("System", "Application")]
    [String]$EventLog = "System", # Defaults to "System"
    # The level of events to gather
    [ValidateRange(0, 4)]
    [UInt32]$EventLevel = 1 # Critical
)

# Set the start date to be $Days before now
$StartDate = (Get-Date).AddDays(-$Days)

# Collect and output all relevant events
Get-WinEvent -FilterHashtable @{LogName = $EventLog; Level = $EventLevel; StartTime = $StartDate } -ErrorAction SilentlyContinue | Select-Object -Last $EventLimit | ForEach-Object {
    [PSCustomObject]@{
        Id          = $_.Id
        Provider    = $_.ProviderName
        Message     = $_.Message
        TimeCreated = [DateTime]$_.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
    }
}
