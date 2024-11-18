# Instructions
[How to use this repository](../../README.md)

# Description
Retrieve Scheduled Tasks including action(s). Tasks can be filtered by TaskName and TaskPath.
Run `Get-Help Get-ScheduledTasksActions.ps1` for more information and examples. 

# Parameters
## TaskName
Specifies an array of one or more names of a scheduled task. You can use "*" for a wildcard character query.

## TaskPath
Specifies an array of one or more paths for scheduled tasks in Task Scheduler namespace. You can use "*" for a wildcard character query. You can use \* for the root folder. To specify a full TaskPath you need to include the leading and trailing \.

# Author
David Bekker