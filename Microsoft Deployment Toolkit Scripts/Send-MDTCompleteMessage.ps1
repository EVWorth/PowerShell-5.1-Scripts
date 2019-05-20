# Enter the SMTP server here
$SMTP = ""
# Enter the From address here
$From = ""
# Enter the To address here
$To = ""
# Enter the Subject here
$Subject = ""
# Enter the Body here
$Body = ""

Send-MailMessage -SmtpServer $SMTP -From $From -To $To -Subject $Subject -body $Body

    
