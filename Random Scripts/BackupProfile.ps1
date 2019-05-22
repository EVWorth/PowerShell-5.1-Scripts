<#
    This script is for backing up user profiles to the users W:\ Drive
    Written By: Elliot Worth
    Date: 5/21/2019
#>
if (!(Test-Path -Path 'W:\Desktop Backup')) {
#List of Processes to kill
    $Processes = "outlook",'winword','excel','msaccess','onenote','onenotem','mspub','powerpnt','chrome','firefox','iexplore','MicrosoftEdge','MicrosoftEdgeCP','MicrosoftEdgeSH'
#Iterate through list of processes, 
    foreach ($Process in $Processes) {
    $Proc = Get-Process -Name $Process -ErrorAction SilentlyContinue
    if ($null -eq $Proc){
        Write-Output "$Process is not running."
    }
    else {
        $Proc | Stop-Process
        Write-Output "$Process stopped."
    }
}
# Create the backup folder in W:/ Drive
    $BackupPath = "W:\Desktop Backup"
    New-Item -Type Directory -Path $BackupPath
# Backup User Profile folders
    Copy-Item -Path $env:USERPROFILE\Desktop -Destination $BackupPath\$Env:USERNAME -Recurse
    Copy-Item -Path $env:USERPROFILE\Documents -Destination $BackupPath\$Env:USERNAME -Recurse
    Copy-Item -Path $env:USERPROFILE\Favorites -Destination $BackupPath\$Env:USERNAME -Recurse
    Copy-Item -Path $env:USERPROFILE\Pictures -Destination $BackupPath\$Env:USERNAME -Recurse
# Backup Chrome/Firefox bookmarks
    Copy-Item -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default" -Destination "$BackupPath\$Env:USERNAME\AppData\Local\Google\Chrome\User Data\" -Recurse
    Copy-Item -Path $env:APPDATA\Mozilla\Firefox\Profiles\ -Destination "$BackupPath\$Env:USERNAME\AppData\Roaming\Mozilla\Firefox\" -Recurse
# Backup office stuff
    Copy-Item -Path $env:LOCALAPPDATA\Microsoft\Office\ -Destination "$BackupPath\$Env:USERNAME\AppData\Local\Microsoft\" -Recurse
    Copy-Item -Path $env:APPDATA\Microsoft\Office\ -Destination "$BackupPath\$Env:USERNAME\AppData\Roaming\Microsoft\" -Recurse
    Copy-Item -Path $env:LOCALAPPDATA\Microsoft\Outlook\ -Destination "$BackupPath\$Env:USERNAME\AppData\Local\Microsoft\" -Recurse
    Copy-Item -Path $env:APPDATA\Microsoft\Outlook\ -Destination "$BackupPath\$Env:USERNAME\AppData\Roaming\Microsoft\" -Recurse
    Copy-Item -Path $env:APPDATA\Microsoft\Templates\ -Destination "$BackupPath\$Env:USERNAME\AppData\Roaming\Microsoft\" -Recurse
    Copy-Item -Path $env:APPDATA\Microsoft\Signatures\ -Destination "$BackupPath\$Env:USERNAME\AppData\Roaming\Microsoft\" -Recurse
    Reg export "HKCU\Software\Microsoft\Shared Tools\Proofing Tools\Custom Dictionaries" "$env:USERPROFILE\Custom_Dictionary.reg"
    Copy-Item -Path $env:USERPROFILE\Custom_Dictionary.reg -Destination "$BackupPath\" -Recurse
# Backup random stuff
    Copy-Item -Path $env:LOCALAPPDATA\Microsoft\Windows\Themes\ -Destination "$BackupPath\$Env:USERNAME\AppData\Local\Microsoft\Windows\" -Recurse
}
else {
    Write-Output "A folder with this name already exists. Delete or rename it before trying to back up this computer."
    break
}







