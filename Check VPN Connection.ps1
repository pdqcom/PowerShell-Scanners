# Written By: Harry Caskey (harrycaskey@gmail.com)
# https://www.harrycaskey.com/detect-vpn-connection-with-powershell/
# In this example, I used "AnyConnect", "Juniper" or "VPN" as the connection name's, but you can change this to whatever fits your environment.
$vpnCheck = Get-ciminstance -Query "Select Name,NetEnabled from Win32_NetworkAdapter where (Name like '%Forti%') and NetEnabled='True'"

# Set this value to Boolean if it returns a value it's true, if it does not return a value it's false.
$vpnCheck = [bool]$vpnCheck

# Check if $vpnCheck is true or false.
if ($vpnCheck) {
    return $vpnCheck
    exit(0)
}
else {
    return $vpnCheck
    exit(1)
}# Written By: Harry Caskey (harrycaskey@gmail.com)
# https://www.harrycaskey.com/detect-vpn-connection-with-powershell/
# In this example, I used "AnyConnect", "Juniper" or "VPN" as the connection name's, but you can change this to whatever fits your environment.
$vpnCheck = Get-ciminstance -Query "Select Name,NetEnabled from Win32_NetworkAdapter where (Name like '%Forti%') and NetEnabled='True'"

# Set this value to Boolean if it returns a value it's true, if it does not return a value it's false.
$vpnCheck = [bool]$vpnCheck

# Check if $vpnCheck is true or false.
if ($vpnCheck) {
    return $vpnCheck
    exit(0)
}
else {
    return $vpnCheck
    exit(1)
}




