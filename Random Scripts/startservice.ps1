# List of Servers
$Servers = "server1","Server2","server3","server4","Server5","server6"
# Name of Service to Start
$Service = "ServiceName"
# Logic to determine where in the array of servers we are at.

$SMTPServer = "YourSMTPServer"
#This doesn't have to be an email address with an inbox
$FromAddress = "ServiceNotification@YourADDomain.tld" 
$ToAddress = "YourEmailAddressOrDistributionList@YourEmailDomain.tld"


# Iterate through list of servers
foreach ($Server in $Servers) {
    # Stop the Service 
    Invoke-Command -ComputerName $Server -ScriptBlock {Get-Service -Name $Service | Stop-Service}
    # Start the Service
    Invoke-Command -ComputerName $Server -ScriptBlock {Get-Service -Name $Service | Start-Service}
    
    $CheckCurrentService = Get-Service -ComputerName $Server -Name $Service
    If ($CheckCurrentService.Status -eq 'Started') {
        $SuccessSubject = "Service: $Service Started Sucessfully on $Server"
        $SuccessBody = "Service: $Service Started Sucessfully on $Server"
        Send-MailMessage -SmtpServer $SMTPServer -From $FromAddress -To $ToAddress -Subject $SuccessSubject -Body $SuccessBody
    }
    else {
        $FailureSubject = "Service: $Service did NOT start Sucessfully on $Server"
        $FailureBody = "Service: $Service did NOT start Sucessfully on $Server"
        Send-MailMessage -SmtpServer $SMTPServer -From $FromAddress -To $ToAddress -Subject $FailureSubject -Body $FailureBody
    }
    $ServerCount ++
}
