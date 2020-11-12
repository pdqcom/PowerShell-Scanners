$current_user = (Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI").LastLoggedOnSAMUser
$current_user_username = ($current_user -split '\\')[1]

$searcher = New-Object system.DirectoryServices.DirectorySearcher
$searcher.PropertiesToLoad.Clear()
$searcher.PropertiesToLoad.AddRange('memberof')
$searcher.filter = "(&(objectclass=user)(samaccountname=$current_user_username))"
$groups = $searcher.FindOne().Properties.memberof
$searcher.PropertiesToLoad.Clear()
$searcher.PropertiesToLoad.AddRange(@('distinguishedname','grouptype','name','samaccountname','mail'))

foreach($group in $groups){
    $searcher.filter = "(&(objectclass=group)(distinguishedname=$group))"
    $groupinfo = $searcher.findone().properties

    switch ($groupinfo.grouptype -as [string]) {
            "2" { 
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupScope -Value "Global"
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupCategory -Value "Distribution"
            }
     
            "8" {
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupScope -Value "Universal"
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupCategory -Value "Distribution"
            }
     
            "-2147483640" { 
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupScope -Value "Universal"
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupCategory -Value "Security"
            }
 
            "-2147483643" {
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupScope -Value "DomainLocal"
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupCategory -Value "Security"
            }
            "-2147483644" {
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupScope -Value "DomainLocal"
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupCategory -Value "Security"
            }
            "-2147483646" {
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupScope -Value "Global"
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupCategory -Value "Security"
            }
            Default {
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupScope -Value "Unknown"
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupCategory -Value "Unknown"
            }
        }

    [PSCustomObject]@{
        'DistinguishedName' = $groupinfo.distinguishedname[0]
        'GroupCategory' = $groupinfo.GroupCategory
        'GroupScope' = $groupinfo.GroupScope
        'Name' = $groupinfo.name[0]
        'SamAccountName' = $groupinfo.samaccountname[0]
        'mail' = if($groupinfo.mail -ne $null){ $groupinfo.mail[0]}else{""}
    }

}