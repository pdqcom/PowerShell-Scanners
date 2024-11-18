<#
.SYNOPSIS
    PDQ Inventory Scanner to retrieve Scheduled Tasks including action(s)
    
.PARAMETER TaskName
    Specifies an array of one or more names of a scheduled task. You can use "*" for a wildcard character query.

.PARAMETER TaskPath
    Specifies an array of one or more paths for scheduled tasks in Task Scheduler namespace. You can use "*" for a wildcard character query. 
    You can use \* for the root folder. To specify a full TaskPath you need to include the leading and trailing \.

.INPUTS
    None. You can't pipe objects.

.OUTPUTS
    System.Management.Automation.PSCustomObject. 
    Get-ScheduledTasksActions.ps1 returns a PSCustomObject each action within a scheduled task.
    Note that a single Scheduled Tasks can have multiple actions.

.LINK
    Parameters TaskName and TaskPath are the same as the built-in cmdlet `Get-ScheduledTask`

.EXAMPLE
    PS> .\Get-ScheduledTasksActions.ps1 -TaskName "Microsoft*"
    TaskName          : Microsoft Compatibility Appraiser
    TaskPath          : \Microsoft\Windows\Application Experience\
    TaskActionExe     : %windir%\system32\compattelrunner.exe
    [...]

#>
param (
    [PSDefaultValue(Help = "Wildcard filter, display all Scheduled Tasks by name")]
    [SupportsWildcards()]
    [string[]]$TaskName = "*",
    [PSDefaultValue(Help = "Wildcard filter, display all Scheduled Tasks by path")]
    [SupportsWildcards()]
    [string[]]$TaskPath = "\*"
)

$tasks = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue

if (!$tasks) {
    throw "No scheduled tasks found"
}

foreach ($task in $tasks) {
    foreach ($action in $task.Actions) {
        [PSCustomObject]@{ 
            TaskName          = $task.TaskName
            TaskPath          = $task.TaskPath
            TaskURI           = $task.URI
            TaskAuthor        = $task.Author
            TaskRunAsUser     = $task.Principal.UserId
            TaskEnabled       = $task.Settings.Enabled
            TaskHidden        = $task.Settings.Hidden
            TaskActionExe     = $action.Execute
            TaskActionArgs    = $action.Arguments
            TaskActionWorkDir = $action.WorkingDirectory
        }
    }
}