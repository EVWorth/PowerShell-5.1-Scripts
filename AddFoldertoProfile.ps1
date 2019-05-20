$Computers = Get-ADComputer -Filter * 

ForEach ($Computer in $Computers) {
    Invoke-Command -ComputerName $Computer -ScriptBlock { 
        $Users = Get-ChildItem -Path C:\Users
        ForEach ($User in $Users) {
            $Folder = Get-ChildItem C:\Users\$User
            if ($User -match "Public") {
                Write-Output "Skipping Public User Profile on: $ENV:COMPUTERNAME"
            }
            else {
                if ($Folder -match "Scans") {
                    Write-Output "Computer Name: $ENV:COMPUTERNAME. Skipping User: $User. Folder already exists."
                }
                else {
                    New-Item -Path C:\Users\$User -Name "Scans" -ItemType "Directory" | Out-Null
                    Write-Output "Computer Name: $ENV:COMPUTERNAME. Creating 'Scans' Folder in User Profile: $User."
                }
            }
        }
        Write-Output "---------------------------------------------------------"
    }
} 
