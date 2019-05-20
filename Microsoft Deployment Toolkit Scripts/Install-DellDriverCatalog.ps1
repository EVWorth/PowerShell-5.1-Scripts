
#requires -Version 4
#Requires -RunAsAdministrator

<#
.SYNOPSIS
Install Drivers from Dell direcly into MDT Litetouch

.DESCRIPTION
This script will download, extract, and install the latest Dell Driver Cab into your local MDT Litetouch environment.

.NOTES
Copyright Keith Garner, All rights reserved. http://deploymentlive.com

Drivers will be placed in the MDT console using the "Total Control" method.
http://www.deploymentresearch.com/Research/tabid/62/EntryId/112/MDT-2013-Lite-Touch-Driver-Management.aspx

In your CS.ini file, set the following:
	DriverSelectionProfile=nothing

Additionally, ensure that your Task sequence has one of the following pairs

	DriverGroup001=Windows 7 x86\%Make%\%Model%
	DriverGroup001=Windows 7 x64\%Make%\%Model%
	DriverGroup001=Windows 8.1 x86\%Make%\%Model%
	DriverGroup001=Windows 8.1 x64\%Make%\%Model%

#>

Function Install-DellDriverCatalog {

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

###############################################################################

Write-verbose "Install-DellDriverCatalog.ps1 8/10/15"

Write-verbose "Find a local MDT Litetouch Deployment Share"
import-module 'C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1' -erroraction Stop

if ( [string]::IsNullOrEmpty( $DeploymentShare ) )
{
	if ( (Get-MDTPersistentDrive).Count -eq 1 )
	{
		$Drive = (Get-MDTPersistentDrive)[0]	# Easy...
	}
	else
	{
		$Drive = Get-MDTPersistentDrive |Out-GridView -passthru -Title "Select Target MDT Deployment Share."
	}
	if ( $Drive -isnot [object] ) { throw "Nothing selected, exit..." }
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

$SupportedList = $DellDriverCatalog.DriverPackManifest.DriverPackage | 
    Where-Object { $_.SupportedOperatingSystems.OperatingSystem.osCode -match "(Windows7|Windows8.1|Windows10)" }

$ApprovedList = @($SupportedList | select-object -Property ReleaseID,
	@{Label="Name";Expression={($_.Name.Display.'#cdata-section')}},
	@{Label="Platform";Expression={($_.SupportedSystems.Brand.Model.Name.Trim() | Select-Object -unique )}},
	@{Label="OS";Expression={ ($_.SupportedOperatingSystems.OperatingSystem | %{ $_.Display.'#cdata-section'.Trim() } | Select-Object -Unique ) }},Size,DateTime,DellVersion,Path,
	@{Label="SupportedOperatingSystems";Expression={ ($_.SupportedOperatingSystems) }} | out-gridview -OutputMode Multiple -Title "Select Driver(s) to import" )

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

	if (-not (get-childitem $DestFolder -recurse -filter "manifest.xml" )) 
    {
        Throw "did not get Driver Package"
    }

	###############################################################################

	foreach ($OSType in $Package.SupportedOperatingSystems.OperatingSystem)
	{

		$OSFolder = $OSType.Display.'#cdata-section'.Trim()
		$PackageModel = $Package.Platform | Select-OBject -unique -first 1

		$DriverPath = "Out-of-Box Drivers\$OSFolder\Dell Inc.\$PackageModel"
		$OSFolder, "\$OSFolder\Dell Inc.", "$OSFolder\Dell Inc.\$PackageModel" | %{ new-DirectorySafe -path "DS001:\Out-of-Box Drivers\$_" }

		foreach ( $Source in "$DestFolder\*\*\$($OSType.OSArch)","$DestFolder\*\$($OSType.OSArch)" | get-childitem )
		{
			write-Verbose "Import [$OSFolder] Dell Driver $($Source.FullName) for platform SrcPath DS001:\$DriverPath"
			Import-MDTDriver -path "DS001:\$DriverPath" -SourcePath $Source.FullName -ImportDuplicates:$ImportDuplicates
		}

	}

}

Write-Verbose "Done!"

}