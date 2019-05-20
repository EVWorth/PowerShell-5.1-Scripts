Stop-Service -Name "wuauserv"
Remove-Item -Path C:\Windows\SoftwareDistribution\Download -Recurse -Force
Start-Service -Name "wuauserv"
