<#
PowerShell to join computer object to Active Directory Group without AD module being imported
This finds the computer object anywhere in AD and adds it to a security group in a known location
#>

#Get computer name
$ComputerName = Get-Content env:computername

#Check to see if computer is already a member of the group
$isMember = new-object DirectoryServices.DirectorySearcher([ADSI]"")
$ismember.filter = "(&(objectClass=computer)(sAMAccountName= $Computername$)(memberof=CN=SecurityGroup,CN=Computers,DC=CORP,DC=LOCAL))"
$isMemberResult = $isMember.FindOne()

#If the computer is already a member of the group, just exit.
If ($isMemberResult) { 
exit 
}
#If the computer is NOT a member of the group, add it.
else
{ 
    $searcher = new-object DirectoryServices.DirectorySearcher([ADSI]"")
    $searcher.filter = "(&(objectClass=computer)(sAMAccountName= $Computername$))"
    $FoundComputer = $searcher.FindOne()
    $P = $FoundComputer | Select-Object path
    $ComputerPath = $p.path
    $GroupPath = "LDAP://CN=SecurityGroup,CN=Computers,DC=CORP,DC=LOCAL"
    $Group = [ADSI]"$GroupPath"
    $Group.Add("$ComputerPath")
    $Group.SetInfo()
}