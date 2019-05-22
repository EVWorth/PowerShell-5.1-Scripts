<#
    This script is for restoring user profiles from the users W:\ Drive
    Written By: Elliot Worth
    Date: 5/21/2019
#>

if (Test-Path -Path 'W:\Desktop Backup') {
    $BackupPath = 'W:\Desktop Backup'
# Import the Custom .Reg files
    reg Import $BackupPath\Custom_Dictionary.reg
# Copy backed up files to new desktop
    Copy-Item -Path $BackupPath\$env:USERNAME -Destination $env:USERPROFILE -Recurse -Force
}
else {
    Write-Output "Backup Folder Doesn't exist. Nothing to Copy."
    break
}