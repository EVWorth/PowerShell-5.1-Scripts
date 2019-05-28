Import-Module ActiveDirectory

$DisabledUsers = Get-ADUser -Filter * -SeachBase "OU=Disabled,Etc" | Where-Object  {$_.Enabled -eq $true} | ForEach-Object {Disable-ADUser -Identity $_}