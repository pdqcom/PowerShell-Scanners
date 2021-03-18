<#
.SYNOPSIS
This function will by default remove all user profiles older than 15 days.

.DESCRIPTION
The function takes in a number of days and then removes all profiles which are as old or older than the number of days.
.PARAMETER DaysBeforeDeletion
An integer representing how old a profile can be before it's removed.
.EXAMPLE
.\Remove-OldUserProfiles.ps1
Running without any additional input will simply remove all profiles older than 30 days on the computer.
.EXAMPLE
.\Remove-OldUserProfiles.ps1 -DaysBeforeDeletion 15
	
This will remove all the profiles which are 15 days or older.
#>
[CmdletBinding()]
param(
	[Parameter(Mandatory=$false)][int]$DaysBeforeDeletion = 15
)
begin {
	if(-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
		Write-Warning -Message "You need to run this script with local administrator privledges."
		break
	}
	Write-Verbose -Message "Starting to remove old profiles."

	# User profiles which should never be removed regardless of age.
	$NeverDelete = @(
		"Administrator",
        "Administratör",
		"Public",
		"LocalService",
		"NetworkService",
		"All Users",
		"Default",
        "systemprofile",
		"Default User"
	)
} process {
	# Get all the user folders, the filter those by folders which have a 
	# last write time which is greater than or equal to the number of days
	# before deletions which has been sent to the script as a parameter.  
	# Then filter the objects to remove any that match our list of profiles
	# Which we never want to delete.
	$OldUserProfiles = @(Get-ChildItem -Force "$($env:SYSTEMDRIVE)\Users" | 
		Where-Object { ((Get-Date)-$_.LastWriteTime).Days -ge $DaysBeforeDeletion } | 
		Where-Object {
		$User = $_
		
		if($NeverDelete.Contains($User.ToString())) {
			$User = $User -replace $User.ToString(), ""
		}

		$User
	} | Where-Object { $_.PSIsContainer })

	# Now go through each user profile and then remove the profile out of win32_userprofile
	# and remove their folder.  This completely removes them from the system and should
	# get around the issue with temporary profiles being created or errors from the system
	# having a record of the profiles existence.
	foreach($UserProfile in $OldUserProfiles) {
		try {
			(Get-WmiObject Win32_UserProfile | Where-Object { $_.LocalPath -like "*$($UserProfile.FullName)*"}).Delete()
			Remove-item -Path $UserProfile.FullName -Force -Recurse
		} catch {
			Write-Error -Message "There was an error removing the user profile $($UserProfile.Name)."
			Write-Error -Message $_.Exception.Message
		}
	}
} end {
	Write-Verbose -Message "User profile folders cleanup complete."
}