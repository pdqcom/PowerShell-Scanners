# Grab the current account from the registry
$account = Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI'
# Grab a global catalog searcher as we have no guarantee in what domain in a forest the account is located
$ds = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().FindGlobalCatalog().GetDirectorySearcher()
# Add in the desired memberof property to the query
[void]$ds.PropertiesToLoad.Add('memberof')
# We search by SID as while a SAM name is unique per domain it's not unique in a forest but the SID is unique in a forest
$ds.Filter = 'objectsid={0}' -f $account.LastLoggedOnUserSID
$groups = $ds.FindOne().Properties['memberof']

# Empty the properties to load from the last query, we don't need them anymore
$ds.PropertiesToLoad.Clear()
# Add in the desired properties for the forthcoming group queries
$ds.PropertiesToLoad.AddRange(@('distinguishedname','grouptype','name','samaccountname','mail'))

# Query for each group found and collect the information
foreach ($group in $groups) {
    $ds.Filter = "(&(objectclass=group)(distinguishedname=$group))"
    $groupinfo = $ds.FindOne().Properties

    # AD stores these values as numbers (bitwise enums really) and here we make them more human friendly
    # Anything positive is always a distribution group; anything negative is always a security group
    switch ($groupinfo.grouptype) {
            2 { 
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupScope -Value "Global"
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupCategory -Value "Distribution"
                break
            }

            4 {
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupScope -Value "DomainLocal"
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupCategory -Value "Distribution"
                break
            }

            8 {
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupScope -Value "Universal"
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupCategory -Value "Distribution"
                break
            }

            -2147483640 { 
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupScope -Value "Universal"
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupCategory -Value "Security"
                break
            }

            -2147483643 {
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupScope -Value "DomainLocal"
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupCategory -Value "Security"
                break
            }

            -2147483644 {
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupScope -Value "DomainLocal"
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupCategory -Value "Security"
                break
            }

            -2147483646 {
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupScope -Value "Global"
                $groupinfo | Add-Member -MemberType Noteproperty -Name GroupCategory -Value "Security"
                break
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
        'GroupType' = $groupinfo.grouptype[0]
        'Name' = $groupinfo.name[0]
        'SamAccountName' = $groupinfo.samaccountname[0]
        'Mail' = if($groupinfo.mail){ $groupinfo.mail[0] }

    }
}
