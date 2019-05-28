$Users = Get-ChildItem -Path C:\Users
ForEach ($User in $Users) {
    $Folder = Get-ChildItem C:\Users\$User
    if ($Folder -match "Scans") {
        Write-Output "Skipping Folder: $User. Folder already exists."
    }
    else {
        New-Item -Path C:\Users\$User -Name "Scans" -ItemType "Directory" | Out-Null
        Write-Output "Creating 'Scans' Folder in Home Folder: $User."
    }
}