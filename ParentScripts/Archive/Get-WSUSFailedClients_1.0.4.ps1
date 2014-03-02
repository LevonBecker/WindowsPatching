#requires –version 2.0

Function Get-WSUSFailedClients {

#region Help

<#
.SYNOPSIS
	Get list of WSUS Clients by WSUS Group.
.DESCRIPTION
	Get list of WSUS Clients by WSUS Group.
.NOTES
	VERSION:    1.0.4
	AUTHOR:     Levon Becker
	EMAIL:      PowerShell.Guru@BonusBits.com 
	ENV:        Powershell v2.0, CLR 2.0+
	TOOLS:      PowerGUI Script Editor
.INPUTS
	ComputerName    Single Hostname
	List            List of Hostnames
	FileName        File with List of Hostnames
	FileBrowser     File with List of Hostnames
	
	DEFAULT FILENAME PATH
	---------------------
	HOSTLISTS
	%USERPROFILE%\Documents\HostList
.OUTPUTS
	DEFAULT PATHS
	-------------
	RESULTS
	%USERPROFILE%\Documents\Results\Get-WSUSFailedClients
	
	LOGS
	%USERPROFILE%\Documents\Logs\Get-WSUSFailedClients
	+---History
	+---JobData
	+---Latest
	+---WIP
.EXAMPLE
	Get-WSUSFailedClients Labs,Excluded,Branch-Offices,"Unassigned Computers"
	Get List of Failed Clients in all groups besides Labs, Excluded, Branch-Offices and UnassignedComputers WSUS Computer Group.
.EXAMPLE
	Get-WSUSFailedClients -ExcludeGroups Labs,Excluded,Branch-Offices,"Unassigned Computers" 
	Get List of Failed Clients in all groups besides Labs, Excluded, Branch-Offices and UnassignedComputers WSUS Computer Group.
.EXAMPLE
	Get-WSUSFailedClients -ExcludeGroups Labs,Excluded,Branch-Offices,"Unassigned Computers"  -SkipOutGrid
	Get List of Failed Clients in all groups besides Labs, Excluded, Branch-Offices and UnassignedComputers WSUS Computer Group.
	Skip displaying the end results that uses Out-GridView
.EXAMPLE
	Get-WSUSFailedClients -ExcludeGroups $GroupList 
	Test a list of hostnames from an already created array variable.
	i.e. $GroupList = @("groupname01","groupname02","groupname03")
.EXAMPLE
	Get-WSUSFailedClients -Groups "Backup-Services" -SkipOutGrid
	Groups:
		Get List of Clients in the Backup-Services WSUS Computer Group.
	SkipOutGrid:
		This switch will skip the results poppup windows at the end.
.PARAMETER ExcludeGroups
	Array parameter for inputing WSUS Computer Group names to get list of clients from.
.PARAMETER UpdateServer
	WSUS server hostname. 
	Short or FQDN works.
.PARAMETER SkipDiskCheck
	This switch will skip the ping and disk check tasks.
.PARAMETER SkipOutGrid
	This switch will skip displaying the end results that uses Out-GridView.
.LINK
	http://wiki.bonusbits.com/main/PSScript:Get-WSUSFailedClients
	http://wiki.bonusbits.com/main/PSModule:WindowsPatching
	http://wiki.bonusbits.com/main/HowTo:Use_WindowsPatching_PowerShell_Module_to_Automate_Patching_with_WSUS_as_the_Client_Patch_Source
	http://wiki.bonusbits.com/main/HowTo:Setup_PowerShell_Module
	http://wiki.bonusbits.com/main/HowTo:Enable_Remote_Signed_PowerShell_Scripts
#>

#endregion Help

#region Parameters

	[CmdletBinding()]
	Param (
#		[parameter(Mandatory=$false,Position=0)][array]$ExcludeGroups = @('Labs','Excluded','Unassigned Computers'),
		[parameter(Mandatory=$false,Position=0)][array]$ExcludeGroups,
		[parameter(Mandatory=$false)][string]$UpdateServer,
		[parameter(Mandatory=$false)][int]$Port = '80',
		[parameter(Mandatory=$false)][switch]$SkipDiskCheck,
		[parameter(Mandatory=$false)][switch]$SkipOutGrid
	)

#endregion Parameters

	If (!$Global:WindowsPatchingDefaults) {
		#  . "$Global:WindowsPatchingModulePath\SubScripts\MultiFunc_Show-WPMErrors_1.0.0.ps1"
		Show-WPMDefaultsMissingError
	}

	# GET STARTING GLOBAL VARIABLE LIST
	New-Variable -Name StartupVariables -Force -Value (Get-Variable -Scope Global | Select -ExpandProperty Name)
	
	# CAPTURE CURRENT TITLE
	[string]$StartingWindowTitle = $Host.UI.RawUI.WindowTitle

#region Variables

	# DEBUG
	$ErrorActionPreference = "Inquire"
	
	# SET ERROR MAX LIMIT
	$MaximumErrorCount = '1000'
	$Error.Clear()

	# SCRIPT INFO
	[string]$ScriptVersion = '1.0.4'
	[string]$ScriptTitle = "Get List of Failed WSUS Clients from the WSUS Server by Levon Becker"
	[int]$DashCount = '68'

	# CLEAR VARIABLES
	[int]$TotalHosts = 0

	# LOCALHOST
	[string]$ScriptHost = $Env:COMPUTERNAME
	[string]$UserDomain = $Env:USERDOMAIN
	[string]$UserName = $Env:USERNAME
	[string]$FileDateTime = Get-Date -UFormat "%Y-%m%-%d_%H.%M"
	[datetime]$ScriptStartTime = Get-Date
	$ScriptStartTimeF = Get-Date -Format g

	# DIRECTORY PATHS
#	[string]$LogPath = ($Global:WindowsPatchingDefaults.GetWSUSFailedClientsLogPath)
#	[string]$ScriptLogPath = Join-Path -Path $LogPath -ChildPath 'ScriptLogs'
	[string]$ResultsPath = ($Global:WindowsPatchingDefaults.GetWSUSFailedClientsResultsPath)
	
	[string]$ModuleRootPath = $Global:WindowsPatchingModulePath
	[string]$SubScripts = Join-Path -Path $ModuleRootPath -ChildPath 'SubScripts'
	[string]$Assets = Join-Path -Path $ModuleRootPath -ChildPath 'Assets'
	
	#region  Set Logfile Name + Create List Array
		
		If ($ExcludeGroups) {
			[Boolean]$ExclusionGroupsPresent = $true
			[array]$ExcludeGroups = $ExcludeGroups | ForEach-Object {$_.ToUpper()}
			If (($ExcludeGroups.Count) -gt 1) {
				[string]$HostInputDesc = "EXCLUDE - " + ($ExcludeGroups | Select -First 2) + " ..."
				[string]$InputItem = "EXCLUDE: " + ($ExcludeGroups | Select -First 2) + " ..."
			}
			Else {
				[string]$HostInputDesc = "EXCLUDE - " + $ExcludeGroups
				[string]$InputItem = "EXCLUDE: " + $ExcludeGroups
			}
			
			[array]$GroupList = $ExcludeGroups
			
			# Remove Duplicates in Array + Get Host Count
			[array]$GroupList = $GroupList | Select -Unique
			[int]$GroupCount = $GroupList.Count
		}
		Else {
			[Boolean]$ExclusionGroupsPresent = $false
			[string]$HostInputDesc = "All Groups"
			[string]$InputItem = "All Groups"
		}
	
	#endregion Set Logfile Name + Create List Array
	
	#region Determine TimeZone
	
		#  . "$SubScripts\Func_Get-TimeZone_1.0.0.ps1"
		Get-TimeZone -ComputerName 'Localhost'
		
		If (($Global:GetTimeZone.Success -eq $true) -and ($Global:GetTimeZone.ShortForm -ne '')) {
			[string]$TimeZoneString = "_" + $Global:GetTimeZone.ShortForm
		}
		Else {
			[string]$TimeZoneString = ''
		}
	
	#endregion Determine TimeZone

	# FILENAMES
	[string]$ResultsTextFileName = "Get-WSUSFailedClients_Results_" + $FileDateTime + $TimeZoneString + "_($HostInputDesc).log"
	[string]$ResultsCSVFileName = "Get-WSUSFailedClients_Results_" + $FileDateTime + $TimeZoneString + "_($HostInputDesc).csv"

	# PATH + FILENAMES
	[string]$ResultsTextFullName = Join-Path -Path $ResultsPath -ChildPath $ResultsTextFileName
	[string]$ResultsCSVFullName = Join-Path -Path $ResultsPath -ChildPath $ResultsCSVFileName

	# MISSING PARAMETERS
	If (!$UpdateServer) {
		[string]$UpdateServer = ($Global:WindowsPatchingDefaults.UpdateServer)
	}


#endregion Variables

#region Check Dependencies
	
	# Create Array of Paths to Dependancies to check
	CLEAR
	$DependencyList = @(
#		"$SubScripts\Func_Get-DiskSpace_1.0.1.ps1",
#		"$SubScripts\Func_Get-Runtime_1.0.3.ps1",
#		"$SubScripts\Func_Get-TimeZone_1.0.0.ps1",
#		"$SubScripts\Func_Reset-WPMUI_1.0.4.ps1",
#		"$SubScripts\Func_Show-ScriptHeader_1.0.2.ps1",
#		"$SubScripts\MultiFunc_Set-WinTitle_1.0.5.ps1",
#		"$SubScripts\MultiFunc_Show-Script-Status_1.0.3.ps1",
		"$ResultsPath"
#		"$SubScripts",
#		"$Assets"
	)

	[array]$MissingDependencyList = @()
	Foreach ($Dependency in $DependencyList) {
		[boolean]$CheckPath = $false
		$CheckPath = Test-Path -Path $Dependency -ErrorAction SilentlyContinue 
		If ($CheckPath -eq $false) {
			$MissingDependencyList += $Dependency
		}
	}
	$MissingDependencyCount = ($MissingDependencyList.Count)
	If ($MissingDependencyCount -gt 0) {
		Clear
		Write-Host ''
		Write-Host "ERROR: Missing $MissingDependencyCount Dependencies" -ForegroundColor White -BackgroundColor Red
		Write-Host ''
		$MissingDependencyList
		Write-Host ''
#		If ((Test-Path -Path "$SubScripts\Func_Reset-WPMUI_1.0.4.ps1") -eq $true) {
#			  . "$SubScripts\Func_Reset-WPMUI_1.0.4.ps1"
			Reset-WPMUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables
#		}
		Break
	}

#endregion Check Dependencies

#region Functions

	
	#  . "$SubScripts\Func_Get-DiskSpace_1.0.1.ps1"
	#  . "$SubScripts\Func_Get-Runtime_1.0.3.ps1"
	#  . "$SubScripts\Func_Reset-WPMUI_1.0.4.ps1"
	#  . "$SubScripts\Func_Show-ScriptHeader_1.0.2.ps1"
	#  . "$SubScripts\MultiFunc_Set-WinTitle_1.0.5.ps1"
		# Set-WinTitleStart
		# Set-WinTitleBase
		# Set-WinTitleInput
		# Set-WinTitleJobCount
		# Set-WinTitleJobTimeout
		# Set-WinTitleCompleted
	#  . "$SubScripts\MultiFunc_Show-Script-Status_1.0.3.ps1"
		# Show-ScriptStatusStartInfo
		# Show-ScriptStatusQueuingJobs
		# Show-ScriptStatusJobsQueued
		# Show-ScriptStatusJobMonitoring
		# Show-ScriptStatusJobLoopTimeout
		# Show-ScriptStatusRuntimeTotals
	
#endregion Functions

#region Show Window Title

	Set-WinTitleStart -Title $ScriptTitle
	Show-ScriptHeader -BlankLines '1' -DashCount $DashCount -ScriptTitle $ScriptTitle

#endregion Show Window Title

#region Console Start Statements
	
	Show-ScriptHeader -BlankLines '4' -DashCount $DashCount -ScriptTitle $ScriptTitle
	# Get PowerShell Version with External Script
	Set-WinTitleBase -ScriptVersion $ScriptVersion 
	[datetime]$ScriptStartTime = Get-Date
	[string]$ScriptStartTimeF = Get-Date -Format g

#endregion Console Start Statements

#region Update Window Title

	Set-WinTitleInput -WinTitleBase $Global:WinTitleBase -InputItem $InputItem
	Show-ScriptHeader -BlankLines '1' -DashCount $DashCount -ScriptTitle $ScriptTitle
	
#endregion Update Window Title

#region Tasks

	#region Load PoshWSUS Module
	
		# CHECK IF MODULE LOADED ALREADY
		If ((Get-Module | Select-Object -ExpandProperty Name | Out-String) -match "PoshWSUS") {
			[Boolean]$ModLoaded = $true
		}
		Else {
			[Boolean]$ModLoaded = $false
		}
		
		# IF MODULE NOT LOADED THEN CHECK IF ON SYSTEM
		If ($ModLoaded -ne $true) {
			Try {
				Import-Module -Name "$ModuleRootPath\Modules\PoshWSUS\PoshWSUS.psd1" -ErrorAction Stop | Out-Null
				[Boolean]$ModLoaded = $true
			}
			Catch {
				[Boolean]$ModLoaded = $false
				Write-Host ''
				Write-Host "ERROR: Failed to Load PoshWSUS Module" -ForegroundColor White -BackgroundColor Red
				Write-Host ''
				Reset-WPMUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables
				Break
			}
		}
	
	#endregion Load PoshWSUS Module
	
	#region Connect to WSUS Server
	
		If ($ModLoaded -eq $true) {
			Try {
				Connect-WSUSServer -WsusServer $UpdateServer -port $Port -ErrorAction Stop | Out-Null
				[Boolean]$WSUSConnected = $true
			}
			Catch {
				[Boolean]$WSUSConnected = $false
				Write-Host ''
				Write-Host "ERROR: Failed to Connect to WSUS Server ($UpdateServer)" -ForegroundColor White -BackgroundColor Red
				Write-Host ''
				Reset-WPMUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables
				Break
			}
		}
	
	#endregion Connect to WSUS Server
		
	#region Main Tasks
	
		If ($WSUSConnected -eq $true) {
			# TASK VARIBLES
#			[boolean]$Failed = $false
#			[boolean]$CompleteSuccess = $false
#			[int]$GroupCount = $GroupList.Count
			
			[int]$TotalHosts = 0
#			Foreach ($WSUSGroup in $GroupList) {
				
				# UPDATE COUNT AND WINTITLE
#				Get-JobCount
#				Set-WinTitleJobCount -WinTitleInput $Global:WinTitleInput -JobCount $Global:getjobcount.JobsRunning
				
				If ($ExclusionGroupsPresent -eq $true) {
					# VERIFY THE WSUS GROUP ENTERED EXISTS
					$WSUSServerGroups = Get-WSUSGroup | Select-Object -ExpandProperty Name
					Foreach ($Group in $GroupList) {
						If ($WSUSServerGroups -notcontains $Group) {
							Write-Host ''
							Write-Host "ERROR: WSUS Group ($Group) does not exist on $UpdateServer" -BackgroundColor Red -ForegroundColor White
							Write-Host ''
							Reset-WPMUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables
							Return
						}
					}
				}
			
				$ClientUpdateSummary = Get-WSUSUpdateSummaryPerClient
				$ClientsWithFailures = $ClientUpdateSummary | Where-Object {$_.FailedCount -gt "0"}
				
				$ClientsWithFailuresCount = $ClientsWithFailures.Count
				
				$FilteredClientList = @()
				
				If ($ExclusionGroupsPresent -eq $true) {
					$ProgressCount = 0
					Foreach ($ComputerName in ($ClientsWithFailures | Select-Object -ExpandProperty Computer)) {
						$TaskProgress = [int][Math]::Ceiling((($ProgressCount / $ClientsWithFailuresCount) * 100))
						# Progress Bar
						Write-Progress -Activity "CHECKING FOR EXCLUSION MATCH ON - ($ComputerName)" -PercentComplete $TaskProgress -Status "OVERALL PROGRESS - $TaskProgress%"
					
						$GroupMemberShip = Get-WSUSClientGroupMembership -Computer $ComputerName | Select-Object -ExpandProperty Name | Where-Object {$_ -ne "All Computers"}
						$InExclusionList = $false
						Foreach ($Group in $GroupList) {
							If ($GroupMemberShip -eq $Group) {
								$InExclusionList = $true
							}
						}
						If ($InExclusionList -eq $false) {
							$FilteredClientList += $ComputerName
						}
						# PROGRESS COUNTER
						$ProgressCount++
					}
					Write-Progress -Activity "CHECKING FOR EXCLUSION MATCH" -Status "COMPLETED" -Completed 
				}
				Else {
					Foreach ($ComputerName in ($ClientsWithFailures | Select-Object -ExpandProperty Computer)) {
						$FilteredClientList += $ComputerName
					}
				}
				
				$ProgressCount = 0
				$FilteredClientListCount = $FilteredClientList.Count
				[array]$Results = @()
				Foreach ($ComputerName in $FilteredClientList) {
					[string]$ScriptErrors = 'None'
					$TotalHosts++
					$TaskProgress = [int][Math]::Ceiling((($ProgressCount / $FilteredClientListCount) * 100))
					# Progress Bar
					Write-Progress -Activity "GATHERING DATA FOR - ($ComputerName)" -PercentComplete $TaskProgress -Status "OVERALL PROGRESS - $TaskProgress%"
									
					$Client = Get-WSUSClient -Computer $ComputerName
					
					[array]$FQDN = $Client.FullDomainName.Split('.')
					[string]$ComputerName = $FQDN[0].ToUpper()
					[string]$ComputerDomain = $FQDN[1] + "." + $FQDN[2] + "." + $FQDN[3]
					[string]$ComputerDomain = $ComputerDomain.ToUpper()
					[string]$HostIP = $Client.IPAddress
					[string]$OSVersion = $Client.OSDescription.Replace(",",'')
					[string]$Make = $Client.Make.Replace(",",'')
					[string]$Model = $Client.Model.Replace(",",'')
					[string]$ClientVersion = $Client.ClientVersion
					[string]$LastSyncTime = $Client.LastSyncTime
					[string]$WSUSGroup = $Client.ComputerGroup | Where-Object {$_ -ne "All Computers"} #^ May want to add for if more than one group output
				
					If ($SkipDiskCheck.IsPresent -eq $false) {
				
					#region Test Connection
					
						If ((Test-Connection -ComputerName $ComputerName -Count 2 -Quiet) -eq $true) {
							[Boolean]$ConnectSuccess = $true
						}
						Else {
							[Boolean]$ConnectSuccess = $false
						}
					
					#endregion Test Connection
					
					#region Get Drive Space
					
						If ($ConnectSuccess -eq $true) {
							## C: DRIVE SPACE CHECK FOR LOGS
							[int]$MinFreeMB = '1000'
							Get-DiskSpace -ComputerName $ComputerName -MinFreeMB $MinFreeMB
							
							# DETERMINE RESULTS
							If ($Global:GetDiskSpace.Success -eq $true) {
								If ($Global:GetDiskSpace.Passed -eq $true) {
#									[boolean]$HardDiskCheckOK = $true
									[string]$FreeSpace = $Global:GetDiskSpace.FreeSpaceMB
									[string]$DriveSize = $Global:GetDiskSpace.DriveSize
								}
								Else {
									[string]$FreeSpace = $Global:GetDiskSpace.FreeSpaceMB
									[string]$DriveSize = $Global:GetDiskSpace.DriveSize
#									[boolean]$Failed = $true
#									[boolean]$HardDiskCheckOK = $false
									[string]$ScriptErrors = "Not Enough Disk Space"
								}
							}
							Else {
#									[boolean]$HardDiskCheckOK = $false
									[string]$FreeSpace = 'Error'
									[string]$DriveSize = 'Error'
#									[boolean]$Failed = $true
									[string]$ScriptErrors = $Global:GetDiskSpace.Notes
							}
						}
						Else {
#							[boolean]$HardDiskCheckOK = $false
							[string]$FreeSpace = 'Unknown'
							[string]$DriveSize = 'Unknown'
							[string]$ScriptErrors = 'Could Not Ping'
						}
					
					#endregion Get Drive Space
				
					} #SkipDiskCheck
					Else {
						[string]$FreeSpace = 'Skipped'
						[string]$DriveSize = 'Skipped'
					}
				
					#region Results
							
#						If (!$ScriptErrors) {
#							[string]$ScriptErrors = 'None'
#						}
#						If ($Failed -eq $false) {
#							[boolean]$CompleteSuccess = $true
#						}
#						Else {
#							[boolean]$CompleteSuccess = $false
#						}

						$TaskResults = New-Object -TypeName PSObject -Property @{
							Hostname = $ComputerName
							Group = $WSUSGroup
							Domain = $ComputerDomain
							IP = $HostIP
							OS = $OSVersion
							DriveSizeMB = $DriveSize
							FreeSpaceMB = $FreeSpace
							Make = $Make
							Model = $Model
							ClientVersion = $ClientVersion
							LastSyncTime = $LastSyncTime
							Errors = $ScriptErrors
							ScriptVersion = $ScriptVersion
							AdminHost = $ScriptHost
							User = $UserName
						}
						$Results += $TaskResults
								
					#endregion Results
					# PROGRESS COUNTER
					$ProgressCount++
				} #/Foreach Client
			Write-Progress -Activity "DATA GATHERING" -Status "COMPLETED" -Completed 
		}
	
	#endregion Get WSUS Client List

#endregion Tasks

#region Write Results to CSV

	# SET DISPLAY ORDER FOR HEADER
	[array]$Header = @(
		"Hostname",
		"Group",
		"Domain",
		"IP",
		"OS",
		"Make",
		"Model",
		"DriveSizeMB",
		"FreeSpaceMB",
		"ClientVersion",
		"LastSyncTime",
		"Errors",
		"ScriptVersion",
		"AdminHost",
		"User"
	)
	$Results | Select-Object $Header | Sort-Object -Property Group,Hostname | Export-Csv -Path $ResultsCSVFullName -NoTypeInformation -Force

#endregion Write Results to CSV

#region Script Completion Updates

	Show-ScriptHeader -BlankLines '1' -DashCount $DashCount -ScriptTitle $ScriptTitle
	Get-Runtime -StartTime $ScriptStartTime
	Show-ScriptStatusRuntimeTotals -StartTimeF $ScriptStartTimeF -EndTimeF $Global:GetRuntime.EndTimeF -Runtime $Global:GetRuntime.Runtime
	Write-Host ''
	Write-Host 'TOTAL GROUPS:    ' -ForegroundColor Green -NoNewline
	Write-Host $GroupCount
	Write-Host 'TOTAL CLIENTS:   ' -ForegroundColor Green -NoNewline
	Write-Host $TotalHosts
	Write-Host ''
	Write-Host 'Results Path:     '  -ForegroundColor Green -NoNewline
	Write-Host "$ResultsPath"
	Write-Host 'Results FileName: '  -ForegroundColor Green -NoNewline
	Write-Host "$ResultsCSVFileName"
	
	Show-ScriptStatusCompleted
	Set-WinTitleCompleted -WinTitleInput $Global:WinTitleInput

#endregion Script Completion Updates

#region Display Report
	
	If ($SkipOutGrid.IsPresent -eq $false) {
		$Results | Select-Object $Header | Sort-Object -Property Group,Hostname | Out-GridView -Title "Get WSUS Clients Results for $InputItem"
	}
	
#endregion Display Report

#region Cleanup UI

	Reset-WPMUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables
	
#endregion Cleanup UI

}

#region Notes

<# Dependents
#>

<# Dependencies
Func_Get-DriveSpace
Func_Get-Runtime
Func_Get-TimeZone
Func_Reset-WPMUI
Func_Show-ScriptHeader
MultiFunc_Set-WinTitle
MultiFunc_Show-Script-Status
#>

<# TO DO
#>

<# Change Log
1.0.0 - 11/06/2012
	Created.
1.0.1 - 11/09/2012
	Finished first stable version
1.0.2 - 12/18/2012
	Switched to Func_Reset-WPMUI 1.0.4
	Changed the results to not write to a temporary file and convert to CSV.
		Instead create a PSObject with the results and add to a Results array.
		Then Output the results array of PSObjects to grid and a CSV file.
	Removed Default Exclusion Groups.
	Added Get-DriveSpace 1.0.1
	Added conditions to deal with no excluded groups.
1.0.3 - 12/18/2012
	Added Reset UI before breaks/returns
	Reworked the Dependency check section.
1.0.4 - 12/28/2012
	Removed Dot sourcing subscripts and load all when module is imported.
	Changed Show-ScriptStatus functions to not have second hypen in name.
	Changed Set-WinTitle functions to not have second hypen in name.
1.0.4 - 01/04/2013
	Removed -SubScript parameter from all subfunction calls.
	Removed dot sourcing subscripts because all are loaded when the module is imported now.
	Removed dependency check for subscripts.
#>


#endregion Notes
