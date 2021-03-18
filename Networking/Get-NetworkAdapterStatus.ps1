<#

   .Synopsis

    Produces a listing of network adapters and status on a local or remote machine.

   .Description

    This script produces a listing of network adapters and status on a local or remote machine.

   .Example

    Get-NetworkAdapterStatus.ps1 -computer MunichServer

    Lists all the network adapters and status on a computer named MunichServer

   .Example

    Get-NetworkAdapterStatus.ps1

    Lists all the network adapters and status on local computer

   .Inputs

    [string]

   .OutPuts

    [string]

   .Notes

    NAME:  Get-NetworkAdapterStatus.ps1

    AUTHOR: Ed Wilson

    LASTEDIT: 1/10/2014

    KEYWORDS: Hardware, Network Adapter

   .Link

     Http://www.ScriptingGuys.com

#Requires -Version 2.0

#>

Param(

  [string]$computer= $env:COMPUTERNAME

) #end param

 

function Get-StatusFromValue

{

 Param($SV)

 switch($SV)

  {

   0 { " Disconnected" }

   1 { " Connecting" }

   2 { " Connected" }

   3 { " Disconnecting" }

   4 { " Hardware not present" }

   5 { " Hardware disabled" }

   6 { " Hardware malfunction" }

   7 { " Media disconnected" }

   8 { " Authenticating" }

   9 { " Authentication succeeded" }

   10 { " Authentication failed" }

   11 { " Invalid Address" }

   12 { " Credentials Required" }

   Default { "Not connected" }

  }

} #end Get-StatusFromValue function

 

# *** Entry point to script ***

 

Get-CimInstance -Class win32_networkadapter -computer $computer | Where-Object Name -notlike %Forti%

Select-Object Name, @{LABEL="Status";

 EXPRESSION={Get-StatusFromValue $_.NetConnectionStatus}}, NetConnectionStatus