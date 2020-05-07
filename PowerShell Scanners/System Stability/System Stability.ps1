
[CmdletBinding()]
param (
    # Number of entries to collect (generated hourly)
    [int]$CollectionWindow = (24 * 7 * 4) #-Default is a four week rolling window
)

# Gather $CollectionWindow worth of ReliabilityStabilityMetrics
$StabilityMetrcs = Get-WmiObject -ClassName Win32_ReliabilityStabilityMetrics | Select-Object -First $CollectionWindow

# Generate Min/Max/Average stability for our collected window.
$StabilityStats = $StabilityMetrcs | Measure-Object -Average -Maximum  -Minimum -Property systemStabilityIndex

# Get the most recent stability and when it was generated
$LastStabitiyMetric = $StabilityMetrcs | Select-Object -First 1 -Property systemStabilityIndex, @{N = "Date"; E = { $_.ConvertToDatetime($_.TimeGenerated) } }

# Output the collected data
[PSCustomObject]@{
    Minimum = [math]::Round($StabilityStats.Minimum)
    Average = [math]::Round($StabilityStats.Average, 2) #round to two decimal places for sanity
    Maximum = [math]::Round($StabilityStats.Maximum)
    Last = $LastStabitiyMetric.systemStabilityIndex
    LastDate = [DateTime]$LastStabitiyMetric.Date
}