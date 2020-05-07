
[CmdletBinding()]
param (
    # Number of days worth of entries to collect
    [int]$Days = 28, # Defaults to Four weeks
    # Limit the number of returned events
    [int]$EventLimit = 30, # Defaults to 30 events
    [ValidateSet("System","Application")]
    [string]$EventLog = "System", # Defaults to "System"
    # The level of events to gather
    [ValidateRange(0,4)]
    [int]$EventLevel = 1 # Critical
)

# Set the start date to be $Days before now
$StartDate = (get-date).adddays(-$Days)

# Collect and output all relevant events
Get-WinEvent -FilterHashtable @{logname=$EventLog; Level=$EventLevel; starttime=$StartDate} -ErrorAction SilentlyContinue | Select-Object -Last $EventLimit | ForEach-Object {
    [PSCustomObject]@{
        Id = $_.Id
        Provider = $_.ProviderName
        Message = $_.Message
        TimeCreated = [datetime]$_.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
    }
}
