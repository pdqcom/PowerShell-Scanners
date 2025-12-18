Hardware Hash



This scanner retrieves the Windows Autopilot Hardware Hash and Serial Number from Windows 10/11 devices. This is essential for IT administrators transitioning from Active Directory to Microsoft Entra ID (formerly Azure AD) and Intune.





Description



The scanner queries the MDM\_DevDetail\_Ext01 WMI class to extract the DeviceHardwareData (the 4K hardware hash). This data is required for manual device registration in the Windows Autopilot service.





Columns Returned



ComputerName: The local hostname.



HardwareHash: The encoded 4K hardware hash.



SerialNumber: The hardware serial number from the BIOS.





Requirements



OS: Windows 10 version 1703 or later.



Hardware: TPM 2.0 is recommended for reliable hash generation.





Usage



1. Import the AutoPilot_Hash.xml scan profile into PDQ Inventory.



2\. Ensure the Get-AutoPilotHash.ps1 file is located in a directory accessible by your PDQ console (or update the scan profile path).



3\. Scan target computers.



4\. Export the results to a CSV using a custom SQL report to match the Intune upload format: Device Serial Number,Windows Product ID,Hardware Hash.





Contributor



Gemini AI and Aaron Smith

