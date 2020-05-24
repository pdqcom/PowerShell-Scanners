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

Sets the severity of events to collect.

Defaults to 1 (Critical)

0 - LogAlways
No level filtering is done on the event.

1 - Critical
This level corresponds to a critical error, which is a serious error that has caused a major failure.

2 - Error
This level adds standard errors that signify a problem.

3 - Warning
This level adds warning events (for example, events that are published because a disk is nearing full capacity).

4 - Informational
This level adds informational events or messages that are not errors. These events can help trace the progress or state of an application.

# Notes

I recommended setting up two instances of this:

## Critical System Events
`-EventLog` System `-EventLevel` 1

## Error Application Events
`-EventLog` Application `-EventLevel` 2

# Author

Ben Gibb
