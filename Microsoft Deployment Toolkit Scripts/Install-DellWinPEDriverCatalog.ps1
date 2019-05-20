<#
.SYNOPSIS
Install Drivers from Dell direcly into MDT Litetouch

.DESCRIPTION
This script will download, extract, and install the latest Dell Driver Cab into your local MDT Litetouch environment.
Will automatically download the correct WinPE driver pack from Dell based on the ADK/WAIK version installed locally.

.NOTES
Copyright Keith Garner, All rights reserved. http://deploymentlive.com

#>

[CmdletBinding()]
Param
(
    [string]$DriverCatalog = "http://downloads.dell.com/catalog/DriverPackCatalog.cab",
    [string]$LocalDriverCache = "$env:SystemDrive\DellDrivers",
    [AllowNull()]
    [ValidateScript({test-path (join-path $_ "control\settings.xml")})]
    [string]$DeploymentShare = $null,
    [switch]$ImportDuplicates = $False
)

#############################################################

$WinPEEnvironments = @{
    winpe5x = "Windows Kits\8.1\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\en-us\winpe.wim"
    winpe10x = "Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\en-us\winpe.wim"
}

###############################################################################

Write-verbose "Install-DellWinPEDriverCatalog 6/1/2015"
Write-verbose "Find a local MDT Litetouch Deployment Share"
import-module 'C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1' -erroraction Stop

if ( [string]::IsNullOrEmpty( $DeploymentShare ) )
{
    if ( Get-MDTPersistentDrive | measure-object | where-object Count -eq 1 )
    {
        $Drive = Get-MDTPersistentDrive | Select-Object -first 1 
    }
    else
    {
        $Drive = Get-MDTPersistentDrive |Out-GridView -passthru -Title "Select Target MDT Deployment Share."
    }
    if ( -not $Drive ) { throw "Nothing selected, exit..." }
    $DeploymentShare = $Drive.Path
}

WRite-Verbose "Load MDT Litetouch Deployment Share $DeploymentShare"
New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root $DeploymentShare | out-string |write-verbose

###############################################################################

function new-DirectorySafe( [string] $Path )
{
    if ( ! ( test-path $Path ) ) { new-item -Type Directory -Path $Path | out-string | write-verbose }
}

Write-Verbose "Download and extract Dell Driver Cab"
New-DirectorySafe -Path $LocalDriverCache
(New-Object System.Net.WebClient).DownloadFile($DriverCatalog, "$LocalDriverCache\DriverPackCatalog.cab")
expand "$LocalDriverCache\DriverPackCatalog.cab" "$LocalDriverCache\DriverPackCatalog.xml" | out-string | write-verbose

write-verbose "Import and parse driver catalog"
[xml]$DellDriverCatalog = get-content "$LocalDriverCache\DriverPackCatalog.xml" -ErrorAction Stop

$ApprovedList = $DellDriverCatalog.DriverPackManifest.DriverPackage | 
    where-object Type -eq "winpe" |
    Where-Object { 
        $WinPEEnvironments.Item($_.SupportedOperatingSystems.OperatingSystem.osCode[0]) | ? { $_ } | %{ join-path (dir env:Program*).Value $_ } | ?{ test-path $_ } 
    } 

if ($ApprovedList.count -gt 1 )
{
    $ApprovedList = $ApprovedList | out-gridview -OutputMode Multiple -Title "Select Driver(s) to import"
}

write-verbose "Found approved drivers: $($ApprovedList.Count)"

foreach ( $Package in $ApprovedList )
{

    $PackageURI = "http://$($DellDriverCatalog.DriverPackManifest.baseLocation)/$($Package.Path)"
    $DestFile = join-Path $LocalDriverCache (split-path -leaf $PackageURI)
    $DestFolder = $DestFile.replace(".CAB","")

    if (!(test-path $DestFolder))
    {
        if (!(test-path $DestFile))
        {
            write-Verbose "Download file $PackageURI"
            if ((get-command invoke-webrequest -erroraction silentlycontinue) -is [object])
            {
                invoke-webrequest -URI $PackageURI -OutFIle $DestFile
            }
            else
            {
                (New-Object System.Net.WebClient).DownloadFile($PackageURI, $DestFile)
            }
        }
        Write-Verbose "Extract $DestFile to $DestFolder"
          new-DirectorySafe -path $DestFolder
        expand.exe -f:* $DestFile $DestFolder | out-string | write-verbose
    }

    if ((get-childitem $DestFolder -recurse -filter "manifest.xml" ) -isnot [object]) { Throw "did not get Driver Package" }

    ###############################################################################

    foreach ( $Platform in $Package.SupportedOperatingSystems.OperatingSystem.osArch )
    {
        if ( (get-item "DS001:").Item("Support$Platform") -eq "True" )
        {
            $DriverPath = "Out-of-Box Drivers\Dell_WinPE_$Platform"
            new-DirectorySafe -path "DS001:\$DriverPath"

            if ( (get-item "DS001:").Item("Boot.$Platform.SelectionProfile") -eq "All Drivers and Packages" )
            {
                new-item -path "DS001:\Selection Profiles" -enable "True" -Name "Dell WinPE $Platform" -Definition "<SelectionProfile><Include path=""$DriverPath"" /></SelectionProfile>" -readonly "false"
                (get-item "DS001:").Item("Boot.$Platform.SelectionProfile") = "Dell WinPE $Platform"
                (get-item "DS001:").Item("Boot.$Platform.IncludeAllDrivers") = "True"
            }

            foreach ( $Source in "$DestFolder\*\*\$Platform","$DestFolder\*\$Platform" | get-childitem )
            {
                write-Verbose "Import $Platform Dell Driver $($Source.FullName) for platform  SrcPath DS001:\$DriverPath"
                Import-MDTDriver -path "DS001:\$DriverPath" -SourcePath $Source.FullName -ImportDuplicates:$ImportDuplicates
            }

        }
    }

}

Write-Verbose "Done!"

