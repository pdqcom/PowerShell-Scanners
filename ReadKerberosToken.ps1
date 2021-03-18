$token = [System.Security.Principal.WindowsIdentity]::GetCurrent() # Get current user context
$groupSIDs = $token.Groups # Get SIDs in current Kerberos token
foreach($sid in $groupSIDs) { # for each of those SIDs...
            try { # try to..
                        Write-Host (($sid).Translate([System.Security.Principal.NTAccount])) # translate the SID to an account name
            }
            catch { # if we can't translate it...
                        Write-Warning ("Could not translate " + $sid.Value + ". Reason: " + $_.Exception.Message) # Output a warning and the corresponding exception
            }
}

# https://activedirectoryfaq.com/2016/08/read-kerberos-token-powershell/
# https://www.google.com/search?rlz=1C1GCEB_enUS925US925&sxsrf=ALeKk00-mI1lpLxLC2MYPBOPHZsq1_CBFg%3A1603768634713&ei=OpGXX5-PK5iqytMPlMia6Ao&q=powershell+kerberos+authentication&oq=powershell+kerbero&gs_lcp=CgZwc3ktYWIQAxgBMgoIABDJAxAUEIcCMgcIABAUEIcCMgIIADICCAAyAggAMgIIADICCAAyBggAEBYQHjIGCAAQFhAeMgYIABAWEB46BAgjECc6BQgAEJECOgsILhCxAxDHARCjAjoFCAAQsQM6CAguEMcBEKMCOg4ILhCxAxCDARDHARCjAjoECAAQQzoHCAAQsQMQQzoICAAQyQMQkQI6BQgAEMkDOgcIABDJAxANOgQIABANOgYIABANEB5Q5UhYyHdgsIgBaAFwAXgAgAFciAH2CJIBAjE5mAEAoAEBqgEHZ3dzLXdpesABAQ&sclient=psy-ab