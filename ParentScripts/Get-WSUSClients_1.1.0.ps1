#requires –version 2.0

Function Get-WSUSClients {

#region Help

<#
.SYNOPSIS
	Get list of WSUS Clients by WSUS Group.
.DESCRIPTION
	Get list of WSUS Clients by WSUS Group.
.NOTES
	VERSION:    1.1.0
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
	%USERPROFILE%\Documents\Results\Get-WSUSClients
	
	LOGS
	%USERPROFILE%\Documents\Logs\Get-WSUSClients
	+---History
	+---JobData
	+---Latest
	+---WIP
.EXAMPLE
	Get-WSUSClients "Backup-Services" 
	Get List of Clients in the Backup-Services WSUS Computer Group.
.EXAMPLE
	Get-WSUSClients -WsusGroups "Backup-Services" 
	Get List of Clients in the Backup-Services WSUS Computer Group.
.EXAMPLE
	Get-WSUSClients -WsusGroups Admin,Backup-Services,Directory-Services
	Get List of Clients from three different WSUS Computer Groups.
.EXAMPLE
	Get-WSUSClients -WsusGroups $GroupList 
	Test a list of hostnames from an already created array variable.
	i.e. $GroupList = @("groupname01","groupname02","groupname03")
.EXAMPLE
	Get-WSUSClients -WsusGroups "Backup-Services" -SkipOutGrid
	Groups:
		Get List of Clients in the Backup-Services WSUS Computer Group.
	SkipOutGrid:
		This switch will skip the results poppup windows at the end.
.PARAMETER WsusGroups
	Array parameter for inputing WSUS Computer Group names to get list of clients from.
.PARAMETER ExcludeGroups
	Array parameter for inputing WSUS Computer Group names to exclude.
	This can be used in conjunction with -WsusGroups "All Computers" -FailedOnly
.PARAMETER UpdateServer
	WSUS server hostname. 
	Short or FQDN works.
.PARAMETER $UpdateServerPort
	TCP Port number to connect to the WSUS Server through IIS.
.PARAMETER FailedOnly
	This switch will return a list of only computers with a status of failed.
.PARAMETER SkipOutGrid
	This switch will skip displaying the end results that uses Out-GridView.
.LINK
	http://www.bonusbits.com/wiki/HowTo:Use_Windows_Patching_PowerShell_Module
	http://www.bonusbits.com/wiki/HowTo:Enable_.NET_4_Runtime_for_PowerShell_and_Other_Applications
	http://www.bonusbits.com/wiki/HowTo:Setup_PowerShell_Module
	http://www.bonusbits.com/wiki/HowTo:Enable_Remote_Signed_PowerShell_Scripts
#>

#endregion Help

#region Parameters

	[CmdletBinding()]
	Param (
		[parameter(Mandatory=$true,Position=0)][array]$WsusGroups,
		[parameter(Mandatory=$false,Position=1)][array]$ExcludeGroups,
		[parameter(Mandatory=$false)][string]$UpdateServer,
		[parameter(Mandatory=$false)][int]$UpdateServerPort,
		[parameter(Mandatory=$false)][switch]$FailedOnly,
		[parameter(Mandatory=$false)][switch]$SkipStatus,
		[parameter(Mandatory=$false)][switch]$SkipOutGrid
	)

#endregion Parameters

	If (!$Global:WindowsPatchingDefaults) {
		Show-WindowsPatchingErrorMissingDefaults
	}

	# GET STARTING GLOBAL VARIABLE LIST
	New-Variable -Name StartupVariables -Force -Value (Get-Variable -Scope Global | Select -ExpandProperty Name)
	
	# CAPTURE CURRENT TITLE
	[string]$StartingWindowTitle = $Host.UI.RawUI.WindowTitle
	
	# SET MISSING PARAMETERS
	If (!$UpdateServer) {
		[string]$UpdateServer = ($Global:WindowsPatchingDefaults.UpdateServer)
	}
	
	If (!$UpdateServerPort) {
		[int]$UpdateServerPort = ($Global:WindowsPatchingDefaults.UpdateServerPort)
	}

#region Variables

	# DEBUG
	$ErrorActionPreference = "Inquire"
	
	# SET ERROR MAX LIMIT
	$MaximumErrorCount = '1000'
	$Error.Clear()

	# SCRIPT INFO
	[string]$ScriptVersion = '1.1.0'
	[string]$ScriptTitle = "Get List of WSUS Clients from the WSUS Server by Levon Becker"
	[int]$DashCount = '61'

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
	[string]$ResultsPath = ($Global:WindowsPatchingDefaults.GetWSUSClientsResultsPath)
	
	[string]$ModuleRootPath = $Global:WindowsPatchingModulePath
	[string]$SubScripts = Join-Path -Path $ModuleRootPath -ChildPath 'SubScripts'
	[string]$Assets = Join-Path -Path $ModuleRootPath -ChildPath 'Assets'
	
	#region  Set Logfile Name + Create List Array
	
		[array]$WsusGroups = $WsusGroups | ForEach-Object {$_.ToUpper()}
		If (($WsusGroups.Count) -gt 1) {
			[string]$InputDesc = "GROUPS - " + ($WsusGroups | Select -First 2) + " ..."
			[string]$InputItem = "GROUPS: " + ($WsusGroups | Select -First 2) + " ..."
		}
		Else {
			[string]$InputDesc = "GROUP - " + $WsusGroups
			[string]$InputItem = "GROUP: " + $WsusGroups
		}
		[array]$GroupList = $WsusGroups
		# Remove Duplicates in Array + Get Host Count
		[array]$GroupList = $GroupList | Select -Unique
		
		#region Remove Excluded Groups
		
			If ($ExcludeGroups.Count -gt 0) {
				Foreach ($GroupName in $ExcludeGroups) {
					[array]$GroupList = $GroupList | Where-Object {$_ -ne $GroupName}
				}
				If ($GroupList -eq $null) {
					Show-ScriptHeader -BlankLines '1' -DashCount $DashCount -ScriptTitle $ScriptTitle
					Write-Host ''
					Write-Host "ERROR: No Groups in List After Removing Excluded Groups" -BackgroundColor Red -ForegroundColor White
					Write-Host ''
					Reset-WindowsPatchingUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables
					Return
				}
			}
		
		#endregion Remove Excluded Groups
		
		[int]$GroupCount = $GroupList.Count
	
	#endregion Set Logfile Name + Create List Array
	
	#region Determine TimeZone
	
		Get-TimeZone -ComputerName 'Localhost'
		
		If (($Global:GetTimeZone.Success -eq $true) -and ($Global:GetTimeZone.ShortForm -ne '')) {
			[string]$TimeZoneString = "_" + $Global:GetTimeZone.ShortForm
		}
		Else {
			[string]$TimeZoneString = ''
		}
	
	#endregion Determine TimeZone

	# FILENAMES
	[string]$ResultsTextFileName = "Get-WSUSClients_Results_" + $FileDateTime + $TimeZoneString + "_($InputDesc).log"
	[string]$ResultsCSVFileName = "Get-WSUSClients_Results_" + $FileDateTime + $TimeZoneString + "_($InputDesc).csv"

	# PATH + FILENAMES
	[string]$ResultsTextFullName = Join-Path -Path $ResultsPath -ChildPath $ResultsTextFileName
	[string]$ResultsCSVFullName = Join-Path -Path $ResultsPath -ChildPath $ResultsCSVFileName

#endregion Variables

#region Check Dependencies
	
	# Create Array of Paths to Dependancies to check
	CLEAR
	$DependencyList = @(
		"$ResultsPath",
		"$SubScripts",
		"$Assets"
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
		Reset-WindowsPatchingUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables
		Break
	}

#endregion Check Dependencies

#region Show Window Title

	Set-WinTitleStart -Title $ScriptTitle
	Show-ScriptHeader -BlankLines '1' -DashCount $DashCount -ScriptTitle $ScriptTitle
	Add-StopWatch
	Start-Stopwatch

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

	#region Connect to WSUS Server
	
		Connect-UpdateServer -UpdateServer $UpdateServer -UpdateServerPort $UpdateServerPort
	
		If ($Global:ConnectUpdateServer.Success -eq $true) {
			[Boolean]$WSUSConnected = $true
		}
		Else {
			[Boolean]$WSUSConnected = $false
			Write-Host ''
			Write-Host "ERROR: Failed to Connect to WSUS Server ($UpdateServer)" -ForegroundColor White -BackgroundColor Red
			Write-Host ''
			Reset-WindowsPatchingUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables
			Return
		}
	
	#endregion Connect to WSUS Server
	
	#region Main Tasks
	
		If ($WSUSConnected -eq $true) {
		
			#region Verify The WSUS Groups Entered Exist
			
				Get-WsusGroups
				If ($Global:GetWsusGroups.Success -eq $true) {
					[array]$WSUSServerGroups = $Global:GetWsusGroups.AllGroupNames
					Foreach ($Group in $GroupList) {
						If ($WSUSServerGroups -notcontains $Group) {
							Show-ScriptHeader -BlankLines '1' -DashCount $DashCount -ScriptTitle $ScriptTitle
							Write-Host ''
							Write-Host "ERROR: WSUS Group ($Group) does not exist on $UpdateServer" -BackgroundColor Red -ForegroundColor White
							Write-Host ''
							Reset-WindowsPatchingUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables
							Return
						}
					}
				}
				Else {
					Show-ScriptHeader -BlankLines '1' -DashCount $DashCount -ScriptTitle $ScriptTitle
					Write-Host ''
					Write-Host "ERROR: Get-WsusGroups SubFunction Failed on $UpdateServer" -BackgroundColor Red -ForegroundColor White
					Write-Host ''
					Reset-WindowsPatchingUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables
					Return
				}
			
			#endregion Verify The WSUS Groups Entered Exist
		
			[int]$GroupCount = $GroupList.Count
#			[int]$GroupProgressCount = 0
			[int]$TotalHosts = 0
			[array]$Results = @()
			
			Foreach ($WsusGroup in $GroupList) {
#				$TaskProgress = [int][Math]::Ceiling((($GroupProgressCount / $GroupCount) * 100))
#				# Progress Bar
#				Write-Progress -Activity "STARTING WSUS CLIENT LOOKUP ON - ($WsusGroup)" -PercentComplete $TaskProgress -Status "OVERALL PROGRESS - $TaskProgress%"
				
				$ClientsInGroup = $null
				Get-ComputersInWsusGroup -WsusGroup $WsusGroup
				If ($Global:GetComputersInWsusGroup.Success -eq $true) {
					# [Microsoft.UpdateServices.Administration.ComputerTargetCollection]
					## of [Microsoft.UpdateServices.Internal.BaseApi.ComputerTarget]
					$ClientsInGroup = $Global:GetComputersInWsusGroup.TargetComputers
					
					[int]$ClientsInGroupCount = $ClientsInGroup.Count
					[int]$ClientProgressCount = 0
					If ($ClientsInGroup -ne $null) {
						Show-ScriptHeader -BlankLines '5' -DashCount $DashCount -ScriptTitle $ScriptTitle
						Foreach ($Client in $ClientsInGroup) {
							$TaskProgress = [int][Math]::Ceiling((($ClientProgressCount / $ClientsInGroupCount) * 100))
							# Progress Bar
							Write-Progress -Activity "GATHERING DATA ON COMPUTERS IN GROUP ($WsusGroup)" -PercentComplete $TaskProgress -Status "OVERALL PROGRESS - $TaskProgress%"
							Show-Stopwatch
							
							[Boolean]$IncludeClient = $true
							
							[array]$FQDN = $Client.FullDomainName.Split('.')
							[string]$FullDomainName = $Client.FullDomainName
							[string]$ComputerName = $FQDN[0].ToUpper()
							[string]$ComputerDomain = $FQDN[1] + "." + $FQDN[2] + "." + $FQDN[3]
							[string]$ComputerDomain = $ComputerDomain.ToUpper()
							[string]$HostIP = $Client.IPAddress
							[string]$OSVersion = $Client.OSDescription.Replace(",",'')
							[string]$Make = $Client.Make.Replace(",",'')
							[string]$Model = $Client.Model.Replace(",",'')
							[string]$ClientVersion = $Client.ClientVersion
							[string]$LastSyncTime = $Client.LastSyncTime

							[array]$ComputerTargetGroups = $Client.GetComputerTargetGroups() | Select-Object -ExpandProperty Name
							If ($ComputerTargetGroups.Count -gt 1) {
								$WsusSubGroups = $null
								Foreach ($SubGroup in $ComputerTargetGroups) {
									If ($SubGroup -ne $WsusGroup) {
										[string]$WsusSubGroups += $SubGroup + ' '
									}
								}
							}
							Else {
								[string]$WsusSubGroups = 'None'
							}
							
							If ($SkipStatus.IsPresent -eq $false) {
								Get-WsusComputerStatus -FullDomainName $FullDomainName
								If ($Global:GetWsusComputerStatus.Success -eq $true) {
									$InstalledCount = $Global:GetWsusComputerStatus.InstalledCount
									$NeededCount = $Global:GetWsusComputerStatus.NeededCount
									$FailedCount = $Global:GetWsusComputerStatus.FailedCount
								}
								Else {
									[string]$ScriptErrors = "FAILED: Get Status "
									$InstalledCount = 'Error'
									$NeededCount = 'Error'
									$FailedCount = 'Error'
								}
								
								If ($FailedOnly.IsPresent -eq $true) {
									# Filter Output to only Failed Systems
									If (($FailedCount -gt 0) -or ($FailedCount -eq 'Error')) {
										[Boolean]$IncludeClient = $true
									}
									Else {
										[Boolean]$IncludeClient = $false
									}
								}
							} # IF Skip Status False
							Else {
									$InstalledCount = 'Skipped'
									$NeededCount = 'Skipped'
									$FailedCount = 'Skipped'
							}

							#region Results
									
								If ($IncludeClient -eq $true) {
									$TotalHosts++
									
									If (!$ScriptErrors) {
										[string]$ScriptErrors = 'None'
									}
									If ($Failed -eq $false) {
										[boolean]$CompleteSuccess = $true
									}
									Else {
										[boolean]$CompleteSuccess = $false
									}
									$TaskResults = New-Object -TypeName PSObject -Property @{
										Hostname = $ComputerName
										Group = $WsusGroup
										SubGroups = $WsusSubGroups
										Domain = $ComputerDomain
										IP = $HostIP
										OS = $OSVersion
										Make = $Make
										Model = $Model
										Installed = $InstalledCount
										Needed = $NeededCount
										Failed = $FailedCount
										ClientVersion = $ClientVersion
										LastSyncTime = $LastSyncTime
										Errors = $ScriptErrors
										ScriptVersion = $ScriptVersion
										AdminHost = $ScriptHost
										User = $UserName
									}
									$Results += $TaskResults
								}
										
							#endregion Results
							
							# TaskProgress Count
							$ClientProgressCount++
						} # Foreach Client
						Write-Progress -Activity "GATHERING DATA ON COMPUTERS IN GROUP ($WsusGroup)" -Status "COMPLETED" -Completed 
					} # IF ClientsInGroup not empty
				} # IF Get-ComputersInWsusGroup successful
				# PROGRESS COUNTER
#				$GroupProgressCount++
			} #/Foreach Group
#			Write-Progress -Activity "STARTING WSUS CLIENT LOOKUP" -Status "COMPLETED" -Completed 
		}
	
	#endregion Main Tasks

#endregion Tasks

#region Write Results to CSV

	# SET DISPLAY ORDER FOR HEADER
	[array]$Header = @(
		"Hostname",
		"Group",
		"SubGroups",
		"Domain",
		"IP",
		"OS",
		"Make",
		"Model",
		"Installed",
		"Needed",
		"Failed",
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

	Reset-WindowsPatchingUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables
	
#endregion Cleanup UI

}

#region Notes

<# Dependents
#>

<# Dependencies
	Get-Runtime
	Get-TimeZone
	Reset-WindowsPatchingUI
	Show-ScriptHeader
	MultiSet-WinTitle
	MultiShow-Script-Status
#>

<# TO DO
#>

<# Change Log
1.0.0 - 10/31/2012
	Created.
1.0.1 -
	WIP
1.0.2 - 11/09/2012
	Finished first stable version
1.0.3 - 12/18/2012
	Switched to Reset-WindowsPatchingUI 1.0.4
	Changed the results to not write to a temporary file and convert to CSV.
		Instead create a PSObject with the results and add to a Results array.
		Then Output the results array of PSObjects to grid and a CSV file.
1.0.4 - 12/18/2012
	Added Reset UI before breaks/returns
	Reworked the Dependency check section.
1.0.5 - 12/28/2012
	Removed Dot sourcing subscripts and load all when module is imported.
	Changed Show-ScriptStatus functions to not have second hypen in name.
	Changed Set-WinTitle functions to not have second hypen in name.
1.0.5 - 01/04/2013
	Removed -SubScript parameter from all subfunction calls.
	Removed dot sourcing subscripts because all are loaded when the module is imported now.
	Removed dependency check for subscripts.
1.0.6 - 01/14/2013
	Renamed WPM to WindowsPatching
1.0.7 - 01/18/2013
	Renamed HostInputDesc to InputDesc
1.0.9 - 01/29/2013
	Renamed Groups parameter to WsusGroups
	Added UpdateServerPort parameter
	Added FailedOnly switch to replace the need for Get-WSUSFailedClients parent script
	Switching to use own custom scripts instead of using PoshWSUS nested module.
#>


#endregion Notes
