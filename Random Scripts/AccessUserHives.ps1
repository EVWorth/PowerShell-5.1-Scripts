New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS

$Users = Get-ChildItem HKU:


foreach ($User in $Users){
    try {
        $UglySID = $User.Name
        $Split = $UglySID.Split('\')
        $SID = $Split[1]
        $FriendlyName = Get-ADUser -Identity $SID -ErrorAction Stop
        if(Test-Path HKU:\$user\Network\T) {
            Remove-Item -Path HKU:\$user\Network\T -Recurse
            Write-Output "Deleted T:\ Drive Mapping from $($FriendlyName.sAMAccountName)"
        }
        else {
            Write-Output "There is no T:\ Drive Mapping for User: $($FriendlyName.sAMAccountName)"
        }
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]{
        "SID: $($User.Name) is not a domain user"
    }

}

Remove-PSDrive -PSProvider Registry -Name HKU