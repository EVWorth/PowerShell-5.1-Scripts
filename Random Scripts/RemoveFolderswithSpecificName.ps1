$Directories = Get-ChildItem -Path \\Path\to\directories\ -Recurse
foreach ($Dir in $Directories) {
    if ($Dir -like "*Hello*"){
        # Dir.PSParentPath/$Dir.Name equals the full file path to $Dir. Otherwise it defaults to the path in $Directories
        Remove-Item -Path "$($Dir.PSParentPath)/$($Dir.Name)" -Recurse -Force -ErrorAction Continue -WarningAction Continue
    }
}