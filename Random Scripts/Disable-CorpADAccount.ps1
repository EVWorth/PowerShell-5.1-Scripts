#Requires -Modules ActiveDirectory
Function Disable-CorpADUser {
    <#
    .SYNOPSIS
        Script for disabling user accounts

	.DESCRIPTION
        Disables the referenced Active Directory user account.
        Changes the password to a randomized string.
        Clears the office and manager fields on the user account.
        Adds the termination date to the description.
        Removes all security group memberships except for Domain Users
        Moves the user to a disabled users OU

	.PARAMETER Identity
		Uses either a single value or a list of values and iterates over each value


	.EXAMPLE 1

	.EXAMPLE 2
	
    
    #>


    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [string]$Identity
    )

ForEach ($User in $Identity) {
    $Username = Get-ADUser -Identity $User

    <# You can add onto this quite a bit with a function to randomly generate. if you are ok with numbers only you can do something like
    $Password = Get-Random -Minimum 8
    #>

    $Password = 'password'
    $Date = Get-Date


    Disable-ADAccount -Identity $Username
    Set-ADAccountPassword -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $Password -Force)
    Set-ADUser -Identity $Username -Clear office,manager
    Set-ADUser -Identity $Username -Description "Termination Date: $Date"
    ForEach ($MemberOf in $Username.$MemberOf) {
        
        if ($MemberOf -like "Domain Users") {
            Write-Verbose "Ignoring Domain Users Security Group"
            }
        else {
            Remove-ADGroupMember -Identity $MemberOf -Members $Username
            }
        }
    Move-ADObject -Identity $Username.DistinguishedName -TargetPath "OU=DisabledUsers,DC=Company,DC=Local"
    }
}