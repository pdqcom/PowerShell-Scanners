# Instructions
[How to use this repository](../../README.md)

# Description

Collects System Stability statistics from Win32_ReliabilityStabilityMetrics and returns:

- Minimum stability over the collected period
- Average stability over the collected period
- Maximum stability over the collected period
- The last generated Stability Index
- Date and time of the last generated Stability Index

# Requirements

Windows 7+

# Parameters

## Count

The number of System Stability Indexes to return.

Windows generates these hourly.

The default is a four week rolling window (24 * 7 * 4)

# Author

Ben Gibb