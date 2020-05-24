[CmdletBinding()]
param (
    # Number of System Stability Indexes to return (generated hourly)
    [UInt32]$Count = (24 * 7 * 4) #-Four week rolling window
)

# Gather $Count worth of ReliabilityStabilityMetrics
$StabilityMetrics = Get-CimInstance -ClassName Win32_ReliabilityStabilityMetrics | Select-Object -First $Count

# Generate Min/Max/Average stability for our collected window.
$StabilityStats = $StabilityMetrics | Measure-Object -Average -Maximum -Minimum -Property SystemStabilityIndex

# Get the most recent stability and when it was generated
$LastStabitiyMetric = $StabilityMetrics | Select-Object -First 1 -Property SystemStabilityIndex, TimeGenerated

# Output the collected data
[PSCustomObject]@{
    Minimum = [math]::Round($StabilityStats.Minimum)
    Average = [math]::Round($StabilityStats.Average, 2) #round to two decimal places for sanity
    Maximum = [math]::Round($StabilityStats.Maximum)
    Last = $LastStabitiyMetric.SystemStabilityIndex
    LastDate = [DateTime]$LastStabitiyMetric.TimeGenerated
}