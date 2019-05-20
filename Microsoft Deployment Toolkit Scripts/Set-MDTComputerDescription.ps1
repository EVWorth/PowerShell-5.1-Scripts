<#
PowerShell to set computer object's Description field without AD module being imported.
This Selects the Computer Object, Gathers data, sets, and saves that data to the AD Object's Description field. 
https://www.reddit.com/r/PowerShell/comments/bo30gi/question_about_setting_a_computer_description_in/
https://docs.microsoft.com/en-us/dotnet/api/system.directoryservices.accountmanagement.computerprincipal?view=netframework-4.8
#>


Add-Type -AssemblyName System.DirectoryServices.AccountManagement
$context = New-Object System.DirectoryServices.AccountManagement.PrincipalContext("Domain")
$ComputerPrincipal = [System.DirectoryServices.AccountManagement.ComputerPrincipal]::FindByIdentity($context, $env:COMPUTERNAME)

$ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
$Manufacturer = $ComputerSystem.Manufacturer
$Model = $ComputerSystem.Model
$ComputerPrincipal.Description = "$Manufacturer $Model"
$ComputerPrincipal.Save()
