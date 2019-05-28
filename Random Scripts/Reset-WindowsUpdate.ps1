$Computername = ''

Invoke-Command -ComputerName $Computername -ScriptBlock {
    Stop-Service -Name "wuauserv" -Verbose
    Remove-Item -Path C:\Windows\SoftwareDistribution\Download -Recurse -Force -Verbose
    Start-Service -Name "wuauserv" -Verbose
}