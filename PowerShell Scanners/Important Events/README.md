# Instructions
[How to use this repository](../../README.md)

# Description

Returns the desired list of events from the event log

# Parameters

## Days

Number of days worth of entries to collect  
Defaults to 28 (four weeks)

## EventLimit

Limit the total number of returned events  
Defaults to 30 events

## EventLog

Either "System", or "Application"  
Defaults to "System"

## EventLevel

Sets the severity of events to collect. Accepts a list of integers.

Example: `1,2,3`

Mostly based on [this list](https://docs.microsoft.com/en-us/windows/win32/wes/eventmanifestschema-leveltype-complextype#remarks).

Defaults to 1 (Critical)

0 - Mistake
Applications should not use this level, but it can happen.

1 - Critical  
An abnormal exit or termination event.

2 - Error  
A severe error event.

3 - Warning  
A warning event such as an allocation failure.

4 - Informational  
A non-error event such as an entry or exit event.

5 - Verbose
A detailed trace event.

# Notes

I recommended setting up two instances of this:

## Critical System Events
`-EventLog` System `-EventLevel` 1

## Error Application Events
`-EventLog` Application `-EventLevel` 2

# Author

Ben Gibb
