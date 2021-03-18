On Error Resume Next

Const wbemFlagReturnImmediately = &h10
Const wbemFlagForwardOnly = &h20

Set wshNetwork = WScript.CreateObject("WScript.Network")
strComputer = wshNetwork.ComputerName

strQuery = "SELECT * FROM DCIM_AssetWarrantyInformation"

WScript.StdOut.WriteLine ""
WScript.StdOut.WriteLine "====================================="
WScript.StdOut.WriteLine "COMPUTER : " & strComputer
WScript.StdOut.WriteLine "CLASS    : ROOT\DCIM\SYSMAN:DCIM_AssetWarrantyInformation"
WScript.StdOut.WriteLine "QUERY    : " & strQuery
WScript.StdOut.WriteLine "====================================="
WScript.StdOut.WriteLine ""

Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\ROOT\DCIM\SYSMAN")
Set colItems = objWMIService.ExecQuery(strQuery, "WQL", wbemFlagReturnImmediately + wbemFlagForwardOnly)

For Each objItem in colItems

    WScript.StdOut.WriteLine "Caption: " & objItem.Caption
    WScript.StdOut.WriteLine "ChangeableType: " & objItem.ChangeableType
    WScript.StdOut.WriteLine "ConfigurationName: " & objItem.ConfigurationName
    WScript.StdOut.WriteLine "Description: " & objItem.Description
    WScript.StdOut.WriteLine "ElementName: " & objItem.ElementName
    WScript.StdOut.WriteLine "Family: " & objItem.Family
    WScript.StdOut.WriteLine "IdentifyingNumber: " & objItem.IdentifyingNumber
    WScript.StdOut.WriteLine "InstanceID: " & objItem.InstanceID
    WScript.StdOut.WriteLine "LastRefreshed: " & objItem.LastRefreshed
    WScript.StdOut.WriteLine "LastRefreshStatus: " & objItem.LastRefreshStatus
    WScript.StdOut.WriteLine "Name: " & objItem.Name
    WScript.StdOut.WriteLine "SKUNumber: " & objItem.SKUNumber
    WScript.StdOut.WriteLine "Vendor: " & objItem.Vendor
    WScript.StdOut.WriteLine "Version: " & objItem.Version
    WScript.StdOut.WriteLine "WarrantyDuration: " & objItem.WarrantyDuration
    WScript.StdOut.WriteLine "WarrantyEndDate: " & objItem.WarrantyEndDate
    WScript.StdOut.WriteLine "WarrantyStartDate: " & objItem.WarrantyStartDate
    WScript.StdOut.WriteLine ""

Next
