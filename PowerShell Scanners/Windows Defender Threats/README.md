# Description

Gather active and past malware threats that Windows Defender detected in the system using the built-in cmdlet `Get-MpThreatDetection` found in the defender module. By default the `Get-MpThreatDetection` command will generate no output if there is no active or history of threats. This isn't very helpful in generating reports since you'll have no output to generate any reports. Once deployed, utilize an eicar text file to generate a false positive and base your reports on that output.

# Requirements

* Windows 10/Server 2016 or higher
* The Windows Defender service must be running

# Author
b0park
