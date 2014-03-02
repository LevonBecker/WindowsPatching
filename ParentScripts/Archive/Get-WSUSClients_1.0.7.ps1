#requires –version 2.0

Function Get-WSUSClients {

#region Help

<#
.SYNOPSIS
	Get list of WSUS Clients by WSUS Group.
.DESCRIPTION
	Get list of WSUS Clients by WSUS Group.
.NOTES
	VERSION:    1.0.7
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
	Get-WSUSClients -Groups "Backup-Services" 
	Get List of Clients in the Backup-Services WSUS Computer Group.
.EXAMPLE
	Get-WSUSClients -Groups Admin,Backup-Services,Directory-Services
	Get List of Clients from three different WSUS Computer Groups.
.EXAMPLE
	Get-WSUSClients -Groups $GroupList 
	Test a list of hostnames from an already created array variable.
	i.e. $GroupList = @("groupname01","groupname02","groupname03")
.EXAMPLE
	Get-WSUSClients -Groups "Backup-Services" -SkipOutGrid
	Groups:
		Get List of Clients in the Backup-Services WSUS Computer Group.
	SkipOutGrid:
		This switch will skip the results poppup windows at the end.
.PARAMETER Groups
	Array parameter for inputing WSUS Computer Group names to get list of clients from.
.PARAMETER UpdateServer
	WSUS server hostname. 
	Short or FQDN works.
.PARAMETER $WsusPort
	TCP Port number to connect to the WSUS Server through IIS.
.PARAMETER SkipOutGrid
	This switch will skip displaying the end results that uses Out-GridView.
.LINK
	http://wiki.bonusbits.com/main/PSScript:Get-WSUSClients
	http://wiki.bonusbits.com/main/PSModule:WindowsPatching
	http://wiki.bonusbits.com/main/HowTo:Use_WindowsPatching_PowerShell_Module_to_Automate_Patching_with_WSUS_as_the_Client_Patch_Source
	http://wiki.bonusbits.com/main/HowTo:Setup_PowerShell_Module
	http://wiki.bonusbits.com/main/HowTo:Enable_Remote_Signed_PowerShell_Scripts
#>

#endregion Help

#region Parameters

	[CmdletBinding()]
	Param (
		[parameter(Mandatory=$true,Position=0)][array]$Groups,
		[parameter(Mandatory=$false)][string]$UpdateServer,
		[parameter(Mandatory=$false)][int]$WsusPort = '80',
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

#region Variables

	# DEBUG
	$ErrorActionPreference = "Inquire"
	
	# SET ERROR MAX LIMIT
	$MaximumErrorCount = '1000'
	$Error.Clear()

	# SCRIPT INFO
	[string]$ScriptVersion = '1.0.7'
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
	
		[array]$Groups = $Groups | ForEach-Object {$_.ToUpper()}
		If (($Groups.Count) -gt 1) {
			[string]$InputDesc = "GROUPS - " + ($Groups | Select -First 2) + " ..."
			[string]$InputItem = "GROUPS: " + ($Groups | Select -First 2) + " ..."
		}
		Else {
			[string]$InputDesc = "GROUP - " + $Groups
			[string]$InputItem = "GROUP: " + $Groups
		}
		[array]$GroupList = $Groups
		# Remove Duplicates in Array + Get Host Count
		[array]$GroupList = $GroupList | Select -Unique
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

	# MISSING PARAMETERS
	If (!$UpdateServer) {
		[string]$UpdateServer = ($Global:WindowsPatchingDefaults.UpdateServer)
	}


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
				Reset-WindowsPatchingUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables
				Break
			}
		}
	
	#endregion Load PoshWSUS Module
	
	#region Connect to WSUS Server
	
		If ($ModLoaded -eq $true) {
			Try {
				Connect-WSUSServer -WsusServer $UpdateServer -port $WsusPort -ErrorAction Stop | Out-Null
				[Boolean]$WSUSConnected = $true
			}
			Catch {
				[Boolean]$WSUSConnected = $false
				Write-Host ''
				Write-Host "ERROR: Failed to Connect to WSUS Server ($UpdateServer)" -ForegroundColor White -BackgroundColor Red
				Write-Host ''
				Reset-WindowsPatchingUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables
				Break
			}
		}
	
	#endregion Connect to WSUS Server
	
	#region Main Tasks
	
		If ($WSUSConnected -eq $true) {
		
			# VERIFY THE WSUS GROUP ENTERED EXISTS
			$WSUSServerGroups = Get-WSUSGroup | Select-Object -ExpandProperty Name
			Foreach ($Group in $GroupList) {
				If ($WSUSServerGroups -notcontains $Group) {
					Write-Host ''
					Write-Host "ERROR: WSUS Group ($Group) does not exist on $UpdateServer" -BackgroundColor Red -ForegroundColor White
					Write-Host ''
					Reset-WindowsPatchingUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables
					Return
				}
			}
		
			[int]$GroupCount = $GroupList.Count
			$i = 0
			[int]$TotalHosts = 0
			[array]$Results = @()
			Foreach ($WSUSGroup in $GroupList) {
				$TaskProgress = [int][Math]::Ceiling((($i / $GroupCount) * 100))
				# Progress Bar
				Write-Progress -Activity "STARTING WSUS CLIENT LOOKUP ON - ($WSUSGroup)" -PercentComplete $TaskProgress -Status "OVERALL PROGRESS - $TaskProgress%"
				
				$ClientsInGroup = Get-WSUSClientsInGroup -Name $WSUSGroup

				Foreach ($Client in $ClientsInGroup) {
					$TotalHosts++
#					$ComputerName = $Client.FullDomainName.Split('.') | Select-Object -First 1
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
				
					#region Results
							
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
							Group = $WSUSGroup
							Domain = $ComputerDomain
							IP = $HostIP
							OS = $OSVersion
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
					
				} #/Foreach Client
				# PROGRESS COUNTER
				$i++
			} #/Foreach Group
			Write-Progress -Activity "STARTING WSUS CLIENT LOOKUP" -Status "COMPLETED" -Completed 
		}
	
	#endregion Main Tasks

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
#>


#endregion Notes
