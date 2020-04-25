#Requires -Module AzureAD
Function Set-O365Licence {
    <#

    .SYNOPSIS
    Set-O365Licence assigns the specified licence to the specified user in AzureAD

    .DESCRIPTION
    The Set-O365Licence cmdlet requests a credential (optional) to connect with, 
    a valid email address, a valid UsageLocation, and a valid SkuId OR a valid SkuPartNumber
    
    Steps include:
    Connecting to AzureAD using the AzureAD Module, 
    either automatically provided a credential or manually requesting information if no credential was provided.
    Setting the Users usage location to US
    Setting the licence based on the SkuId or SkuPart Number provided
    
    
    

	.PARAMETER   
		

    .EXAMPLE 1
    Set-O365Licence -Identity user.name@companydomain.com -SkuId '########-####-####-####-############' -UsageLocation 'US'

	.EXAMPLE 2
	Set-O365Licence -Identity user.name@companydomain.com -SkuId '########-####-####-####-############' -UsageLocation 'US' -Credential (Get-Credential) 	

    .EXAMPLE 3
    Set-O365Licence -Identity user.name@companydomain.com -SkuPartNumber 'WINDOWS_STORE' -UsageLocation 'US' -Credential (Get-Credential)

	.INPUTS
		
    .NOTES
    You can find the SkuPartNumber(s) in your tenant using the following command: Get-AzureADSubscribedSku
    #>


    [CmdletBinding()]
    Param (
        [Parameter(ParameterSetName = 'SkuId','SkuPartNumber')]
        [System.Management.Automation.PSCredential]$Credential,
        [Parameter(Mandatory,ParameterSetName = 'SkuId','SkuPartNumber')]
        [ValidateNotNullOrEmpty()]
        [string]$Identity,
        [Parameter(Mandatory,ParameterSetName = 'SkuId','SkuPartNumber')]
        [ValidateNotNullOrEmpty()]
        [string]$UsageLocation,
        [Parameter(Mandatory,ParameterSetName = 'SkuId')]
        [ValidateNotNullOrEmpty()]
        [string]$SkuId,
        [Parameter(Mandatory,ParameterSetName = 'SkuPartNumber')]
        [ValidateNotNullOrEmpty()]
        [string]$SkuPartNumber

    )

    try {

        #Region Authentication
        if ($Credential) {
            try {
                Connect-AzureAD -Credential $Credential -ErrorAction Stop
            }
            catch {
                Write-Output "Error: Credential data was incorrect. Defaulting to manual authentication"
                try {
                    Connect-AzureAD
                }
                catch [AadAuthenticationFailedException, AggregateException, AdalServiceException] {
                    Write-Output "Error: User canceled authentication"
                }
                catch {
                }
            }
        }
        else {
            try {
                Connect-AzureAD
            }
            catch [AadAuthenticationFailedException, AggregateException, AdalServiceException] {
                Write-Output "Error: User canceled authentication"
            }
            catch {
            }
        }
        #EndRegion


        
        #Region Checking and setting UsageLocation
        $CurrentUsageLocation = (Get-AzureADUser -ObjectId $Identity | Select-Object UsageLocation).UsageLocation
        if ($CurrentUsageLocation -eq $UsageLocation) {
            Write-Output "UsageLocation is correct. No changes needed."
        }
        else {
            Set-AzureADUser -ObjectId $Identity -UsageLocation US
        }
        #EndRegion 

        #Region Set Licence and Licenses variables
        $License = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
        $Licenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
            #Checking to see if the SkuId value is a valid sku
            #or if it is a SkuPartNumber that we must check against the AzureAD tenant
        if ($SkuId) {
            #Verifying the part number against the Skus in the tenant
            $SkuPart = Get-AzureADSubscribedSku | Select-Object SkuPartNumber
            foreach ($Part in $SkuPart) {
                if ($SkuId -eq (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -eq -Value $Part).SkuID) {
                    $license.SkuId = $SkuId
                    $Licenses.AddLicenses = $License
                }
                else {
                    Write-Output "The Supplied Sku: ($SkuId) does not match a Sku found in the tenant."
                    Write-Output "Exiting Script"
                    Exit
                }
            }
        }
            #We must be using the SkuPartNumber
        else {
            $SkuId = (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -eq -Value $SkuPartNumber).SkuID
            if ($SkuId) {
                $license.SkuId = $SkuId
                $Licenses.AddLicenses = $License
            }
            else {
                Write-Output "The supplied SkuPartNumber: ($SkuPartNumber) does not return data for a SkuPartNumber found in the tenant."
                Write-Output "Exiting Script"
                Exit
            }
        }
        #EndRegion


        #Set the Licence for the user
        Set-AzureADUserLicense -ObjectId $Identity -AssignedLicenses $Licenses


    }
    catch {
    
    }
    finally {
        try { Disconnect-AzureAD -ErrorAction Stop } 
        catch [System.NullReferenceException] {
            Write-Output "Error: Attempted to disconnect from AzureAD but there were no open sessions"
        }
    }
}