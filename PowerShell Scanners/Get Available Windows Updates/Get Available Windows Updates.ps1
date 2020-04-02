& '.\Install and Import Module.ps1' -ModuleName "PSWindowsUpdate"

# The PowerShell Scanner currently does not understand the Collection object this cmdlet emits,
# so we have to assign it to a variable to get PowerShell to unwrap it for us.
$GWU = Get-WindowsUpdate
$GWU