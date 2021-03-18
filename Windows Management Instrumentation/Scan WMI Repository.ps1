# https://social.technet.microsoft.com/Forums/office/en-US/78d69ac9-2bc2-4526-8df6-94ccc093dd5f/powershell-inconsistency-invokecommand-w-quotwinmgmt-verifyrepositoryquot?forum=ITCG
# PDQ Source https://help.pdq.com/hc/en-us/articles/220532447-WMI-Diagnostics
Invoke-Command -ComputerName l2dz9433.int.efwnow.com -ScriptBlock { winrm quickconfig, winmgmt /verifyrepository }

## Scans WMI Repository if errors, Suspect your WInRM setup.  Run WMIDiag on at least one system and be sure the setup is fully functional. or Re-Register WMI Components on the target machine.

<#

Support Help Center home page
PDQ.com home Community Submit a request 
Support  General  General Documentation
Search

Articles in this section
WMI Diagnostics
 Brigg Angus
3 years ago Updated
Purpose:
You have received an error or are experiencing an issue related to Windows Management Instrumentation (WMI). WMI is used extensively by PDQ Inventory and to a much lesser extent by PDQ Deploy.

NOTE: WMI is also used to refer to the WMI Repository, located here: %WINDIR%\System32\wbem\Repository.

Resolution:
Identifying, testing and resolving WMI errors are covered in the following:

Common WMI Errors
Additional Tools and Troubleshooting
Recommended Fixes

Common WMI Errors
Below are some common errors encountered with WMI and the recommended fixes, if applicable.

WMI Operation Timed Out
PDQ Inventory queries the WMI Repository of target machines when performing most scanning tasks. In cases where scan overlap can occur, or if a target computer’s resources are insufficient to complete the WMI queries within the default 90-second timeout, the WMI Operation Timed Out error is the result.
01.png

You can modify the WMI Timeout by navigating to PDQ Inventory’s Options > Preferences > Performance and changing the WMI Timeout setting:
02.png

WMI Object Not Found
This error typically represents some corruption of the WMI Repository. Remediation steps are located below or (in much abbreviated form) in the WMI Object Not Found KB article.

WMI Initialization Failure
This error can be caused by corruption of the WMI Repository or by a device driver that is preventing the WMI system from starting up properly. For help with a corrupt WMI Repository, please see the recommendations below.

WMI Provider Load Failure
This error typically represents an issue with a registered WMI component or (less common) WMI Repository corruption. Please see the recommended fixes below.

WMI Invalid Class
This error is likely caused by missing data in the WMI Repository. Please see the recommended fixes below to rebuild the WMI database. If you receive this error as part of a WMI scan, the issue is likely due to a misspelling of the class (more information can be found here).

WMI Repository On Target May Need Repair
This error is caused by corruption of the WMI Repository, which can be caused by a number of things, including improperly installed drivers.

WMI Operation Failed
This error generally occurs when the WMI Repository is corrupt. Please see the recommended fixes below to rebuild the WMI database. This error can also be caused by a misconfigured DCOM component. For this error, there should be additional information in the Event Viewer logs.


Additional Tools and Troubleshooting

PDQ Inventory:
With the introduction of the WMI scanner in version 15 of PDQ Inventory, you can use a WMI scanner to scan a remote machine to see if the scan results in an error. While it is unlikely the error will provide much in the way of a specific diagnosis, it will likely provide corroboration as to whether the WMI Repository needs to be repaired or reset.

WMI Diagnosis Utility
Microsoft has provided a tool to help in diagnosing WMI issues, which you can download here: WMI Diagnosis Utility - Version 2.2. While the WMI Diagnosis Utility is no longer supported starting with Windows 8 and Windows Server 2012, it is possible to run the utility on those platforms.

WMI Explorer:
WMI Explorer has been bundled with PDQ Inventory 15+. (Options > Scan Profiles > [WMI scan profile] > Edit > [WMI scanner] > Edit > Launch WMI Explorer). Optionally, you can download the tool here. The application allows you to navigate the WMI database and create/run queries.

If there are WMI errors, WMI Explorer is likely to also throw errors. For additional information on using WMI Explorer, please see this article.

WBemTest
This utility is accessed on any Windows OS from  %WINDIR%\System32\wbem\wbemtest.exe. For information on how to use this tool, please see this Introduction to WBemTest.

PowerShell
Get-CimInstance can be used to troubleshoot WMI issues by issuing WMI queries. For more information on using Get-CimInstance, including several example queries, please see this Microsoft article.

WMIC
This is Microsoft's (now deprecated) utility to access WMI via the Windows command line. More information on WMIC is located here. To run a WMI query against a remote computer, use the following syntax:

wmic /node:"computername" cpu list
For example, to get CPU data for the target, v-lab01-aa, you would run the following:

wmic /node:"v-lab01-aa" cpu list
Or test being able to spawn a remote process in WMI on v-lab01-aa:

wmic /node:"v-lab01-aa" process call create "notepad.exe"
NOTE: If successful, a notepad.exe process will be created on the target computer. This will not necessarily open up an instance of notepad.

Additional Resources:
WMI Troubleshooting
WMI Isn't Working!
WMI Error Constants


Recommended Fixes
If there is an issue with the WMI Repository, the steps below are designed to take you through most of the WMI fixes currently available.

NOTE: when repairing or rebuilding the WMI Repository, the winmgmt command will complete quickly. Be aware that although the command(s) complete, the rebuild process can take around 30 minutes to complete. We recommend waiting at least 30 minutes before attempting another scan on the target machine.

1. Check the Repository of the target machine:
Run the following command from an administrative/elevated command prompt:

winmgmt /verifyrepository
2. Re-Register WMI Components on the target machine:

If inconsistencies are found, you can re-register the DLLs and recompile the MOFs using the following commands, in order, from an administrative/elevated command prompt:

sc config winmgmt start= disabled
net stop winmgmt /y
cd %windir%\system32\wbem
for /f %s in ('dir /b *.dll') do regsvr32 /s %s
wmiprvse /regserver
sc config winmgmt start= auto
net start winmgmt
for /f %s in ('dir /s /b *.mof *.mfl') do mofcomp %s
Reboot the machine and attempt to scan the target again.

NOTE: It might also be necessary to re-register the WMI components in %windir%\sysWOW64\wbem depending on the architecture of the machine. To do this, run the above as-is then follow the same procedure using the cd %windir%\sysWOW64\wbem command instead of cd %windir%\system32\wbem.

IMPORTANT:
If running this as a bat file, change the following lines,

for /f %s in ('dir /b *.dll') do regsvr32 /s %s
for /f %s in ('dir /s /b *.mof *.mfl') do mofcomp %s
To,

for /f %%s in ('dir /b *.dll') do regsvr32 /s %%s
for /f %%s in ('dir /s /b *.mof *.mfl') do mofcomp %%s
3. Check the Repository on the target machine again:
Run the following command from an administrative/elevated command prompt:

winmgmt /verifyrepository
4. Salvage the Repository:
If there are still issues, run the following from an administrative/elevated command prompt:

winmgmt /salvagerepository
This checks the WMI Repository for consistency. If an inconsistency exists, the Repository is rebuilt and the contents of the inconsistent Repository are merged into the rebuilt Repository. This operation should not be destructive.

5. Use Microsoft’s WMI Diagnostic utility for additional troubleshooting:
You can download the utility here. Once downloaded and extracted, it is recommended you read the WMIDiag.doc for information on using the utility. Once the utility is run, check the log files for additional information on what might be the issue with WMI.

6. Reset the Repository:
And finally, if the WMIDiag tool isn’t helpful and the target is still experiencing issues, you can reset the WMI Repository to its original state from when the OS was installed.

WARNING: Resetting the WMI Repository can impact third-party applications installed on the affected target. It is possible that some applications will no longer function properly until they are re-installed on the target machine.

Use the following command from an administrative/elevated command prompt on the impacted target machine:

winmgmt /resetrepository
Once the above command is run on the target machine, wait for 30 minutes then attempt to scan again.

Facebook Twitter LinkedIn
 3
Was this article helpful?
 
4 out of 4 found this helpful
Have more questions? Submit a request
Return to top
Recently viewed articles
How to troubleshoot Kerberos and NTLM authentication
Signing Your PowerShell Scripts
Can't access ADMIN$ share using a local user account
LAPS Integration with PDQ Inventory and PDQ Deploy
Kerberos: The target account name is incorrect
Related articles
Error: WMI Invalid Namespace
Inventory WMI Scanner: Usage & Examples
Windows Firewall Ports and Exceptions
Invalid Service Account, Account Name and/or Password is Invalid or Does Not Exist
Server Setup with PDQ Link
Comments
3 commentsSort by 

Glenn Pearson
9 years ago
Looking good now....with the troubleshooting steps you provided you have pointed me in the right direction. I actually had to rebuild the WMI Repository, now the computer scans without issues.

Thanks again for the prompt response and keep up the good fight!!!

0
Comment actions

Ryan Mills
6 years ago
The steps above solved the PC WMI issues in PDQ Inventory.  I used PDQ Deploy and created a custom install package using a command line and it worked perfectly.  The two products go hand in hand!  

Thanks a bunch for the great troubleshooting steps!

0
Comment actions

Dowd Peggy
6 years ago
Still can't get the packages to download. 

0
Comment actions
Article is closed for comments.
Support


#>