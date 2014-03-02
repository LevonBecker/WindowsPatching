#requires –version 2.0

Function Set-WindowsPatchingDefaults {

#region Help

<#
.SYNOPSIS
	Sets default global variables for the Window Patching Module.
.DESCRIPTION
	This is used with several of the Windows Patching Module scripts to reduce 
	parameter typing and keep the scripts universal.
.NOTES
	VERSION:    1.0.5
	AUTHOR:     Levon Becker
	EMAIL:      PowerShell.Guru@BonusBits.com 
	ENV:        Powershell v2.0, CLR 2.0+
	TOOLS:      PowerGUI Script Editor
.EXAMPLE
	Set-WindowsPatchingDefaults -vCenter "vcenter01.domain.com" -UpdateServerURL "http://wsus01.domain.com"
	Sets the defaults, creates missing folders and displays the results.
.EXAMPLE
	Set-WindowsPatchingDefaults -vCenter "vcenter01.domain.com" -UpdateServerURL "http://wsus01.domain.com"
	Sets the defaults, creates missing folders and does not display the results.
.PARAMETER UpdateServerURL
	URL used in registry for clients to communicate to the WSUS Server.
.PARAMETER UpdateServer
	WSUS Server Hostname for connection for reports.
.PARAMETER RootLogPath
	This is the full path to the root directory where logs will be created.
	The default is your user profile documents folder under WindowsPowerShell.
	This can be change to any local or network mapped drive, but be beware
	if using a network mapped drive because latency may cause issues.
	Of course double check permissions with the account running PowerShell
	as well.
.PARAMETER HostListRootPath
	This is the full path to the root directory where Host List Files
	Can be placed and is the default location the FileBrowser function will
	look.
	The default is your user profile documents folder.
	This can be change to any local or network mapped drive, but be beware
	if using a network mapped drive because latency may cause issues.
	Of course double check permissions with the account running PowerShell
	as well.
.PARAMETER ResultsRootPath
	This is the full path to the root directory where the results spreadsheets
	will be created.
	The default is your user profile documents folder.
	This can be change to any local or network mapped drive, but be beware
	if using a network mapped drive because latency may cause issues.
	Of course double check permissions with the account running PowerShell
	as well.
.PARAMETER NoHeader
	This switch will skip showing the Module Header after initial load.
.PARAMETER NoTips
	This switch will skip showing the Module Header after initial load.
.PARAMETER Quiet
	If this switch is used the results will not be displayed.
.LINK
	http://wiki.bonusbits.com:PSScript:Set-WindowsPatchingDefaults
	http://wiki.bonusbits.com/main/PSModule:WindowsPatching
	http://wiki.bonusbits.com/main/HowTo:Use_WindowsPatching_PowerShell_Module_to_Automate_Patching_with_WSUS_as_the_Client_Patch_Source
	http://wiki.bonusbits.com/main/HowTo:Setup_PowerShell_Module
	http://wiki.bonusbits.com/main/HowTo:Enable_Remote_Signed_PowerShell_Scripts
#>

#endregion Help

	Param (
		[parameter(Position=0,Mandatory=$true)][string]$UpdateServer,
		[parameter(Position=1,Mandatory=$true)][string]$UpdateServerURL,
		[parameter(Position=2,Mandatory=$false)][string]$UpdateServerPort = "80",
		[parameter(Mandatory=$false)][string]$RootLogPath = "$Env:USERPROFILE\Documents",
		[parameter(Mandatory=$false)][string]$HostListRootPath = "$Env:USERPROFILE\Documents",
		[parameter(Mandatory=$false)][string]$ResultsRootPath = "$Env:USERPROFILE\Documents",
		[parameter(Mandatory=$false)][switch]$NoHeader,
		[parameter(Mandatory=$false)][switch]$NoTips,
		[parameter(Mandatory=$false)][switch]$Quiet
	)
	
	# REMOVE EXISTING OUTPUT PSOBJECT	
	If ($Global:WindowsPatchingDefaults) {
		Remove-Variable WindowsPatchingDefaults -Scope "Global"
	}
	
	[Boolean]$NoHeaderBool = ($NoHeader.IsPresent)
	[Boolean]$NoTipsBool = ($NoTips.IsPresent)
	
	If ($NoHeader.IsPresent -eq $true) {
		Clear
	}
	
	#region Tasks
	
		#region Set Module Paths
	
			[string]$ModuleRootPath = $Global:WindowsPatchingModulePath
			[string]$SubScripts = Join-Path -Path $ModuleRootPath -ChildPath 'SubScripts'
			[string]$Assets = Join-Path -Path $ModuleRootPath -ChildPath 'Assets'
			
		#region Set Module Paths
	
		#region Create Log Directories
		
			# CREATE WINDOWSPOWERSHELL DIRECTORY IF MISSING
			## using different variables incase the RootLogPath parameter is changed.
			[string]$UserDocsFolder = "$Env:USERPROFILE\Documents"
			[string]$UserPSFolder = "$Env:USERPROFILE\Documents\WindowsPowerShell"
			[string]$LogPath = "$RootLogPath\Logs"
			[string]$ResultsPath = "$ResultsRootPath\Results"
			[string]$HostListPath = "$HostListRootPath\HostLists"
			[string]$InstallPatchesResultsPath = "$ResultsPath\Install-Patches"
			[string]$TestWSUSClientResultsPath = "$ResultsPath\Test-WSUSClient"
			[string]$GetPendingPatchesResultsPath = "$ResultsPath\Get-PendingPatches"
			[string]$GetWSUSFailedClientsResultsPath = "$ResultsPath\Get-WSUSFailedClients"
			[string]$GetWSUSClientsResultsPath = "$ResultsPath\Get-WSUSClients"
			[string]$MoveWSUSClientToGroupResultsPath = "$ResultsPath\Move-WSUSClientToGroup"
			
			
			If ((Test-Path -Path $UserPSFolder) -eq $false) {
				New-Item -Path $UserDocsFolder -Name 'WindowsPowerShell' -ItemType Directory -Force | Out-Null
			} 
		
			# CREATE ROOT DIRECTORIES IF MISSING
			If ((Test-Path -Path $LogPath) -eq $false) {
				New-Item -Path $RootLogPath -Name 'Logs' -ItemType Directory -Force | Out-Null
			}
			If ((Test-Path -Path $HostListPath) -eq $false) {
				New-Item -Path $HostListRootPath -Name 'HostLists' -ItemType Directory -Force | Out-Null
			}
			If ((Test-Path -Path $ResultsPath) -eq $false) {
				New-Item -Path $ResultsRootPath -Name 'Results' -ItemType Directory -Force | Out-Null
			}
			If ((Test-Path -Path $TestWSUSClientResultsPath) -eq $false) {
				New-Item -Path $ResultsPath -Name 'Test-WSUSClient' -ItemType Directory -Force | Out-Null
			}
			If ((Test-Path -Path $InstallPatchesResultsPath) -eq $false) {
				New-Item -Path $ResultsPath -Name 'Install-Patches' -ItemType Directory -Force | Out-Null
			}
			If ((Test-Path -Path $GetPendingPatchesResultsPath) -eq $false) {
				New-Item -Path $ResultsPath -Name 'Get-PendingPatches' -ItemType Directory -Force | Out-Null
			}
			If ((Test-Path -Path $GetWSUSFailedClientsResultsPath) -eq $false) {
				New-Item -Path $ResultsPath -Name 'Get-WSUSFailedClients' -ItemType Directory -Force | Out-Null
			}
			If ((Test-Path -Path $GetWSUSClientsResultsPath) -eq $false) {
				New-Item -Path $ResultsPath -Name 'Get-WSUSClients' -ItemType Directory -Force | Out-Null
			}
			If ((Test-Path -Path $MoveWSUSClientToGroupResultsPath) -eq $false) {
				New-Item -Path $ResultsPath -Name 'Move-WSUSClientToGroup' -ItemType Directory -Force | Out-Null
			}
		
			# ROOT LOG DIRECTORIES
			$InstallPatchesLogPath = Join-Path -Path $LogPath -ChildPath 'Install-Patches'
			$TestWSUSClientLogPath = Join-Path -Path $LogPath -ChildPath 'Test-WSUSClient'
			$GetPendingPatchesLogPath = Join-Path -Path $LogPath -ChildPath 'Get-PendingPatches'
			$GetWSUSFailedClientsLogPath = Join-Path -Path $LogPath -ChildPath 'Get-WSUSFailedClients'
#			$GetWSUSClientsLogPath = Join-Path -Path $LogPath -ChildPath 'Get-WSUSClients'

			# CREATE LOG ROOT DIRECTORIES IF MISSING
			If ((Test-Path -Path $InstallPatchesLogPath) -eq $false) {
				New-Item -Path $LogPath -Name 'Install-Patches' -ItemType Directory -Force | Out-Null
			}
			If ((Test-Path -Path $TestWSUSClientLogPath) -eq $false) {
				New-Item -Path $LogPath -Name 'Test-WSUSClient' -ItemType Directory -Force | Out-Null
			}
			If ((Test-Path -Path $GetPendingPatchesLogPath) -eq $false) {
				New-Item -Path $LogPath -Name 'Get-PendingPatches' -ItemType Directory -Force | Out-Null
			}
#			If ((Test-Path -Path $GetWSUSFailedClientsLogPath) -eq $false) {
#				New-Item -Path $LogPath -Name 'Get-WSUSFailedClients' -ItemType Directory -Force | Out-Null
#			}
#			If ((Test-Path -Path $GetWSUSClientsLogPath) -eq $false) {
#				New-Item -Path $LogPath -Name 'Get-WSUSClients' -ItemType Directory -Force | Out-Null
#			}

			$SubFolderList = @(
				'History',
				'JobData',
				'Latest',
				'WIP'
			)

			# CREATE SUB DIRECTORIES IF MISSING (Install-Patches)
			Foreach ($folder in $SubFolderList) {
				If ((Test-Path -Path "$InstallPatchesLogPath\$folder") -eq $false) {
					New-Item -Path $InstallPatchesLogPath -Name $folder -ItemType Directory -Force | Out-Null
				}
			}
			# Extra Directory for Install-Patches VBS script Last Patches Log (Install-Patches)
			If ((Test-Path -Path "$InstallPatchesLogPath\Temp") -eq $false) {
					New-Item -Path $InstallPatchesLogPath -Name Temp -ItemType Directory -Force | Out-Null
			}
			# CREATE SUB DIRECTORIES IF MISSING (Test-WSUSClient)
			Foreach ($folder in $SubFolderList) {
				If ((Test-Path -Path "$TestWSUSClientLogPath\$folder") -eq $false) {
					New-Item -Path $TestWSUSClientLogPath -Name $folder -ItemType Directory -Force | Out-Null
				}
			}
			# CREATE SUB DIRECTORIES IF MISSING (Get-PendingPatches)
			Foreach ($folder in $SubFolderList) {
				If ((Test-Path -Path "$GetPendingPatchesLogPath\$folder") -eq $false) {
					New-Item -Path $GetPendingPatchesLogPath -Name $folder -ItemType Directory -Force | Out-Null
				}
			}
#			# CREATE SUB DIRECTORIES IF MISSING (Get-WSUSFailedClients)
#			Foreach ($folder in $SubFolderList) {
#				If ((Test-Path -Path "$GetWSUSFailedClientsLogPath\$folder") -eq $false) {
#					New-Item -Path $GetWSUSFailedClientsLogPath -Name $folder -ItemType Directory -Force | Out-Null
#				}
#			}
#			# CREATE SUB DIRECTORIES IF MISSING (Get-WSUSClients)
#			Foreach ($folder in $SubFolderList) {
#				If ((Test-Path -Path "$GetWSUSClientsLogPath\$folder") -eq $false) {
#					New-Item -Path $GetWSUSClientsLogPath -Name $folder -ItemType Directory -Force | Out-Null
#				}
#			}
		
		#endregion Create Log Directories
	
	#endregion Tasks
	
	# Create Results Custom PS Object
	$Global:WindowsPatchingDefaults = New-Object -TypeName PSObject -Property @{
		UpdateServerURL = $UpdateServerURL
		UpdateServer = $UpdateServer
		ModuleRootPath = $ModuleRootPath
		SubScripts = $SubScripts
		Assets = $Assets
		RootLogPath = $RootLogPath
		UserDocsFolder = $UserDocsFolder
		UserPSFolder = $UserPSFolder
		HostListPath = $HostListPath
		ResultsPath = $ResultsPath
		NoHeader = $NoHeaderBool
		NoTips = $NoTipsBool
		InstallPatchesLogPath = $InstallPatchesLogPath
		InstallPatchesResultsPath = $InstallPatchesResultsPath
		TestWSUSClientLogPath = $TestWSUSClientLogPath
		TestWSUSClientResultsPath = $TestWSUSClientResultsPath
		GetPendingPatchesLogPath = $GetPendingPatchesLogPath
		GetPendingPatchesResultsPath = $GetPendingPatchesResultsPath
		GetWSUSFailedClientsResultsPath = $GetWSUSFailedClientsResultsPath
		GetWSUSClientsResultsPath = $GetWSUSClientsResultsPath
		MoveWSUSClientToGroupResultsPath = $MoveWSUSClientToGroupResultsPath
	}
	If ($Quiet.IsPresent -eq $false) {
		$Global:WindowsPatchingDefaults | Format-List
	}
}

#region Notes

<# Description
	Function for the WindowsPatching Module to set default folder location and create missing folders.
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Get-PendingPatches
	Install-Patches
	Test-WSUSClient
#>

<# Dependencies
	
#>

<# To Do List

	 
#>

<# Change Log
1.0.0 - 05/01/2012
	Created
1.0.0 - 05/02/2012
	Removed UpdateServer parameter. May add it later, but not used currently.
	.PARAMETER UpdateServer
		FQDN to WSUS server used to feed approved patches to hosts.
 	-UpdateServer "wsus01.domain.com"
	Removed Defaults and put them in my user profile startup script.
1.0.1 - 05/02/2012
	Moved Log directory creation to be done by this script instead of module.
	Added parameters with defaults for setting the log root locations.
	Added
		RootLogPath
		InstallPatchesLogPath
		TestWSUSClientLogPath
1.0.2 - 05/10/2012
	Added NoHeader
	Added NoTips
1.0.3 - 05/14/2012
	Added Get-PendingPatches sections
1.0.3 - 05/15/2012
	Renamed ScriptLogs and ScriptResults folder to Logs and Results
	Moved Logs to root of documents folder
	Removed ScriptLogs sub folder
1.0.3 - 05/16/2012
	Removed FailedAccess logic now that it's in the results.
1.0.4 - 10/22/2012
	Added UpdateServer hostname parameter
1.0.5 - 12/17/2012
	Remove vCenter as part of removing PowerCLI from WindowsPatching Module.
1.0.6 - 01/04/2013
	Added Move-WSUSClientToGroup
1.0.7 - 01/22/2013
	Renamed PendingUpdates to PendingPatches
#>

#endregion Notes
