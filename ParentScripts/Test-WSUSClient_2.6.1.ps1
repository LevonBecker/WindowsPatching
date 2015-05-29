
Function Test-WSUSClient {

#region Help

<#
.SYNOPSIS
	Automation Script.
.DESCRIPTION
	Script for automating a process.
.NOTES
	VERSION:    2.6.1
	AUTHOR:     Levon Becker
	EMAIL:      PowerShell.Guru@BonusBits.com 
	ENV:        Powershell v2.0, CLR 4.0+
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
	%USERPROFILE%\Documents\Results\Test-WSUSClient
	
	LOGS
	%USERPROFILE%\Documents\Logs\Test-WSUSClient
	+---History
	+---JobData
	+---Latest
	+---WIP
.EXAMPLE
	Test-WSUSClient -ComputerName server01 
	Patch a single computer.
.EXAMPLE
	Test-WSUSClient server01 
	Patch a single computer.
	The ComputerName parameter is in position 0 so it can be left off for a
	single computer.
.EXAMPLE
	Test-WSUSClient -List server01,server02
	Test a list of hostnames comma separated without spaces.
.EXAMPLE
	Test-WSUSClient -List $MyHostList 
	Test a list of hostnames from an already created array variable.
	i.e. $MyHostList = @("server01","server02","server03")
.EXAMPLE
	Test-WSUSClient -FileBrowser 
	This switch will launch a separate file browser window.
	In the window you can browse and select a text or csv file from anywhere
	accessible by the local computer that has a list of host names.
	The host names need to be listed one per line or comma separated.
	This list of system names will be used to perform the script tasks for 
	each host in the list.
.EXAMPLE
	Test-WSUSClient -FileBrowser -SkipOutGrid
	FileBrowser:
		This switch will launch a separate file browser window.
		In the window you can browse and select a text or csv file from anywhere
		accessible by the local computer that has a list of host names.
		The host names need to be listed one per line or comma separated.
		This list of system names will be used to perform the script tasks for 
		each host in the list.
	SkipOutGrid:
		This switch will skip the results poppup windows at the end.
.EXAMPLE
	Test-WSUSClient -WsusGroups group01 
	This will query the WSUS Server for a list of hostnames in a single or
	multiple WSUS groups to run the script against.
	This is an array so more than one can be listed as a comma seperated list
	without spaces.
.EXAMPLE
	Test-WSUSClient -WsusGroups group01,group02,group03 
	This will query the WSUS Server for a list of hostnames in a single or
	multiple WSUS groups to run the script against.
	This is an array so more than one can be listed as a comma seperated list
	without spaces.
.EXAMPLE
	Test-WSUSClient -FileBrowser -SkipPolicyUpdate -SkipSettingsReset
	FileBrowser:
		This switch will launch a separate file browser window.
		In the window you can browse and select a text or csv file from anywhere
		accessible by the local computer that has a list of host names.
		The host names need to be listed one per line or comma separated.
		This list of system names will be used to perform the script tasks for 
		each host in the list.
	SkipPolicyUpdate:
		This switch will skip the task to update the computer and user policies 
		on the remote computers.
	SkipSettingsReset:
		This switch will skip the task to reset the Windows Update service 
		settings and re-register the remote system with the WSUS server.
.PARAMETER ComputerName
	Short name of Windows host to patch
	Do not use FQDN 
.PARAMETER List
	A PowerShell array List of servers to patch or comma separated list of host
	names to perform the script tasks on.
	-List server01,server02
	@("server1", "server2") will work as well
	Do not use FQDN
.PARAMETER FileBrowser
	This switch will launch a separate file browser window.
	In the window you can browse and select a text or csv file from anywhere
	accessible by the local computer that has a list of host names.
	The host names need to be listed one per line or comma separated.
	This list of system names will be used to perform the script tasks for 
	each host in the list.
.PARAMETER WsusGroups
	A PowerShell array List of WSUS Groups to query for hostnames.
.PARAMETER MaxJobs
	Maximum amount of background jobs to run simultaneously. 
	Adjust depending on how much memory and load the localhost can handle.
	Because the entire task is rather quick it's better to keep this number 
	low for overall speed.
	It's not recommended to set higher than 400.
	Default = 100
.PARAMETER JobQueTimeout
	Maximum amount of time in seconds to wait for the background jobs to finish 
	before timing out. 	Adjust this depending out the speed of your environment 
	and based on the maximum jobs ran simultaneously.
	
	If the MaxJobs setting is turned down, but there are a lot of servers this 
	may need to be increased.
	
	This timer starts after all jobs have been queued.
	Default = 300 (5 minutes)
.PARAMETER UpdateServerURL
	Microsoft WSUS Server URL used by the remote computers.
	This is the URL clients have in their registry pointing them to the WSUS
	server.
.PARAMETER UpdateServer
	WSUS server hostname. 
	Short or FQDN works.
.PARAMETER UpdateServerPort
	TCP Port number to connect to the WSUS Server through IIS.
.PARAMETER SkipOutGrid
	This switch will skip displaying the end results that uses Out-GridView.
.PARAMETER SkipPolicyUpdate
	This switch will skip the task to update the computer and user policies on 
	the	remote computers.
.PARAMETER SkipSettingsReset
	This switch will skip the task to reset the Windows Update service settings 
	and re-register the remote system with the WSUS server.
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
		[parameter(Mandatory=$false,Position=0)][string]$ComputerName,
		[parameter(Mandatory=$false)][array]$List,
		[parameter(Mandatory=$false)][switch]$FileBrowser,
		[parameter(Mandatory=$false)][array]$WsusGroups,
		[parameter(Mandatory=$false)][int]$MaxJobs = '200', #Because the entire task is rather quick it's better to keep this low for overall speed.
		[parameter(Mandatory=$false)][int]$JobQueTimeout = '900', #This timer starts after all jobs have been queued.
		[parameter(Mandatory=$false)][string]$UpdateServer,
		[parameter(Mandatory=$false)][string]$UpdateServerURL,
		[parameter(Mandatory=$false)][int]$UpdateServerPort,
		[parameter(Mandatory=$false)][switch]$SkipPolicyUpdate,
		[parameter(Mandatory=$false)][switch]$SkipSettingsReset,
		[parameter(Mandatory=$false)][switch]$SkipOutGrid
	)

#endregion Parameters

	If (!$Global:WindowsPatchingDefaults) {
#		. "$Global:WindowsPatchingModulePath\SubScripts\MultiShow-WPMErrors_1.0.0.ps1"
		Show-WindowsPatchingErrorMissingDefaults
	}

	# GET STARTING GLOBAL VARIABLE LIST
	New-Variable -Name StartupVariables -Force -Value (Get-Variable -Scope Global | Select -ExpandProperty Name)
	
	# CAPTURE CURRENT TITLE
	[string]$StartingWindowTitle = $Host.UI.RawUI.WindowTitle

	# SET MISSING PARAMETERS
	If (!$UpdateServerURL) {
		[string]$UpdateServerURL = ($Global:WindowsPatchingDefaults.UpdateServerURL)
	}
	
	If (!$UpdateServer) {
		[string]$UpdateServer = ($Global:WindowsPatchingDefaults.UpdateServer)
	}
	
	If (!$UpdateServerPort) {
		[int]$UpdateServerPort = ($Global:WindowsPatchingDefaults.UpdateServerPort)
	}
	
	# PATHS NEEDED AT TOP
	[string]$ModuleRootPath = $Global:WindowsPatchingModulePath
	[string]$SubScripts = Join-Path -Path $ModuleRootPath -ChildPath 'SubScripts'
	[string]$HostListPath = ($Global:WindowsPatchingDefaults.HostListPath)

#region Prompt: Missing Input

	#region Prompt: FileBrowser
	
		If ($FileBrowser.IsPresent -eq $true) {
#			. "$Global:WindowsPatchingModulePath\SubScripts\Get-FileName_1.0.0.ps1"
			Clear
			Write-Host 'SELECT FILE CONTAINING A LIST OF HOSTS TO PATCH.'
			Get-FileName -InitialDirectory $HostListPath -Filter "Text files (*.txt)|*.txt|Comma Delimited files (*.csv)|*.csv|All files (*.*)|*.*"
			[string]$FileName = $Global:GetFileName.FileName
			[string]$HostListFullName = $Global:GetFileName.FullName
		}
	
	#endregion Prompt: FileBrowser

	#region Prompt: Host Input

		If (!($FileName) -and !($ComputerName) -and !($List) -and !($WsusGroups)) {
			[boolean]$HostInputPrompt = $true
			Clear
			$promptitle = ''
			
			$message = "Please Select a Host Entry Method:`n"
			
			# HM = Host Method
			$hmc = New-Object System.Management.Automation.Host.ChoiceDescription "&ComputerName", `
			    'Enter a single hostname'

			$hml = New-Object System.Management.Automation.Host.ChoiceDescription "&List", `
			    'Enter a List of hostnames separated by a commas without spaces'
				
			$hmf = New-Object System.Management.Automation.Host.ChoiceDescription "&File", `
			    'Text file name that contains a List of ComputerNames'
				
			$hmg = New-Object System.Management.Automation.Host.ChoiceDescription "&WsusGroups", `
			    'Enter a List of WSUS Group names separated by commas without spaces'
			
			$exit = New-Object System.Management.Automation.Host.ChoiceDescription "E&xit", `
			    'Exit Script'

			$options = [System.Management.Automation.Host.ChoiceDescription[]]($hmc, $hml, $hmf, $hmg, $exit)
			
			$result = $host.ui.PromptForChoice($promptitle, $message, $options, 4) 
			
			# RESET WINDOW TITLE AND BREAK IF EXIT SELECTED
			If ($result -eq 4) {
				Clear
				Reset-WindowsPatchingUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables -SkipPrompt
				Break
			}
			Else {
			Switch ($result)
				{
				    0 {$HostInputMethod = 'ComputerName'} 
					1 {$HostInputMethod = 'List'}
					2 {$HostInputMethod = 'File'}
					3 {$HostInputMethod = 'WsusGroup'}
				}
			}
			Clear
			
			# PROMPT FOR COMPUTERNAME
			If ($HostInputMethod -eq 'ComputerName') {
				Do {
					Clear
					Write-Host ''
#					Write-Host 'Short name of a single host.'
					$ComputerName = $(Read-Host -Prompt 'ENTER COMPUTERNAME')
				}
				Until ($ComputerName)
			}
			# PROMPT FOR LIST 
			Elseif ($HostInputMethod -eq 'List') {
				Write-Host 'Enter a List of hostnames separated by a comma without spaces to patch.'
				$commaList = $(Read-Host -Prompt 'Enter List')
				# Read-Host only returns String values, so need to split up the hostnames and put into array
				[array]$List = $commaList.Split(',')
			}
			# PROMPT FOR FILE
			Elseif ($HostInputMethod -eq 'File') {
#				. "$Global:WindowsPatchingModulePath\SubScripts\Get-FileName_1.0.0.ps1"
				Clear
				Write-Host ''
				Write-Host 'SELECT FILE CONTAINING A LIST OF HOSTS TO PATCH.'
				Get-FileName -InitialDirectory $HostListPath -Filter "Text files (*.txt)|*.txt|Comma Delimited files (*.csv)|*.csv|All files (*.*)|*.*"
				[string]$FileName = $Global:GetFileName.FileName
				[string]$HostListFullName = $Global:GetFileName.FullName
			}
			Elseif ($HostInputMethod -eq 'WsusGroup') {
				Write-Host 'Enter a List of WSUS Group names separated by commas without spaces.'
				$commaList = $(Read-Host -Prompt 'Enter WSUS Groups')
				# Read-Host only returns String values, so need to split up the hostnames and put into array
				[array]$WsusGroups = $commaList.Split(',')
			}
			Else {
				Write-Host 'ERROR: Host method entry issue'
				Reset-WindowsPatchingUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables
				Break
			}
		}
		
	#endregion Prompt: Host Input
		
	#region Prompt: GPO Update

		If ($HostInputPrompt -eq $true) {
			Clear
			$title = ""
			$message = "PERFORM A GPO UPDATE ON CLIENTS?"

			$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
			    "Selecing yes will update the AD Group Policies on the ComputerNames."

			$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
			    "Selecting no will skip updating the AD Group Policies on the ComputerNames"

			$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

			$result = $host.ui.PromptForChoice($title, $message, $options, 0) 

			switch ($result)
			{
			    0 {[switch]$SkipPolicyUpdate = $false} 
			    1 {[switch]$SkipPolicyUpdate = $true} 
			}
		}

	#endregion Prompt: GPO Update

	#region Prompt: Reset Client WU Settings

		If ($HostInputPrompt -eq $true) {
			Clear
			$title = ""
			$message = "RESET WINDOWS UPDATE SETTINGS ON CLIENTS?"

			$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
			    "Copy batch file to ComputerName and run to reset reg settings, start/stop service, reauth and trigger detect"

			$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
			    "Do not run Reset-WUSettings.cmd on the Host List"

			$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

			$result = $host.ui.PromptForChoice($title, $message, $options, 0) 

			switch ($result)
			{
			    0 {[switch]$SkipSettingsReset = $false} 
			    1 {[switch]$SkipSettingsReset = $true} 
			}
		}

	#endregion Prompt: Reset Client WU Settings

#endregion Prompt: Missing Input

#region Variables

	# DEBUG
	$ErrorActionPreference = "Inquire"
	
	# SET ERROR MAX LIMIT
	$MaximumErrorCount = '1000'
	$Error.Clear()

	# SCRIPT INFO
	[string]$ScriptVersion = '2.6.1'
	[string]$ScriptTitle = "Test WSUS Client Setting by Levon Becker"
	[int]$DashCount = '40'

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
	[string]$LogPath = ($Global:WindowsPatchingDefaults.TestWSUSClientLogPath)
	[string]$ScriptLogPath = Join-Path -Path $LogPath -ChildPath 'ScriptLogs'
	[string]$JobLogPath = Join-Path -Path $LogPath -ChildPath 'JobData'
	[string]$ResultsPath = ($Global:WindowsPatchingDefaults.TestWSUSClientResultsPath)
	
	[string]$Assets = Join-Path -Path $ModuleRootPath -ChildPath 'Assets'
	
	#region  Set Logfile Name + Create HostList Array
	
		If ($ComputerName) {
			[string]$InputDesc = $ComputerName.ToUpper()
			# Inputitem is also used at end for Outgrid
			[string]$InputItem = $ComputerName.ToUpper() #needed so the WinTitle will be uppercase
			[array]$HostList = $ComputerName.ToUpper()
		}
		ElseIF ($List) {
			[array]$List = $List | ForEach-Object {$_.ToUpper()}
			[string]$InputDesc = "LIST - " + ($List | Select -First 2) + " ..."
			[string]$InputItem = "LIST: " + ($List | Select -First 2) + " ..."
			[array]$HostList = $List
		}		
		ElseIf ($FileName) {
			[string]$InputDesc = $FileName
			# Inputitem used for WinTitle and Out-GridView Title at end
			[string]$InputItem = $FileName
			If ((Test-Path -Path $HostListFullName) -ne $true) {
					Clear
					Write-Host ''
					Write-Host "ERROR: INPUT FILE NOT FOUND ($HostListFullName)" -ForegroundColor White -BackgroundColor Red
					Write-Host ''
					Reset-WindowsPatchingUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables
					Break
			}
			[array]$HostList = Get-Content $HostListFullName
			[array]$HostList = $HostList | ForEach-Object {$_.ToUpper()}
		}
		ElseIF ($WsusGroups) {
		
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
			
			#region Get HostNames
			
				If ($WSUSConnected -eq $true) {
					
					#region Verify The WSUS Groups Entered Exist
					
						Get-WsusGroups
						If ($Global:GetWsusGroups.Success -eq $true) {
							[array]$WSUSServerGroups = $Global:GetWsusGroups.AllGroupNames
							Foreach ($Group in $WsusGroups) {
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
					
					[array]$HostList = @()
					Foreach ($WsusGroup in $WsusGroups) {
						$ClientsInGroup = $null
						Get-ComputersInWsusGroup -WsusGroup $WsusGroup
						If ($Global:GetComputersInWsusGroup.Success -eq $true) {
							# [Microsoft.UpdateServices.Administration.ComputerTargetCollection]
							## of [Microsoft.UpdateServices.Internal.BaseApi.ComputerTarget]
							$ClientsInGroup = $Global:GetComputersInWsusGroup.TargetComputers

							If ($ClientsInGroup -ne $null) {
								Foreach ($Client in $ClientsInGroup) {
									[array]$FQDN = $Client.FullDomainName.Split('.')
									[string]$ComputerName = $FQDN[0].ToUpper()
									$HostList += $ComputerName
								}
							}
						}
					}
					If ($HostList.Count -eq '0') {
						Show-ScriptHeader -BlankLines '1' -DashCount $DashCount -ScriptTitle $ScriptTitle
						Write-Host ''
						Write-Host "ERROR: No Computers Found in ($WSUSGroups)" -BackgroundColor Red -ForegroundColor White
						Write-Host ''
						Reset-WindowsPatchingUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables
						Return
					}
				}
				
			#endregion Get HostNames
		
			If ($WsusGroups.Count -gt 2) {
				[string]$InputDesc = "GROUPS - " + ($WsusGroups | Select -First 2) + " ..."
				[string]$InputItem = "GROUPS: " + ($WsusGroups | Select -First 2) + " ..."
			}
			Else {
				[string]$InputDesc = "GROUPS - " + ($WsusGroups)
				[string]$InputItem = "GROUPS: " + ($WsusGroups)
			}
			
		}
		Else {
			Clear
			Write-Host ''
			Write-Host "ERROR: INPUT METHOD NOT FOUND" -ForegroundColor White -BackgroundColor Red
			Write-Host ''
			Reset-WindowsPatchingUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables
			Break
		}
		# Remove Duplicates in Array + Get Host Count
		[array]$HostList = $HostList | Select -Unique
		[int]$TotalHosts = $HostList.Count
	
	#endregion Set Logfile Name + Create HostList Array
	
	#region Determine TimeZone
	
		Get-TimeZone -ComputerName 'Localhost'
		
		If (($Global:GetTimeZone.Success -eq $true) -and ($Global:GetTimeZone.ShortForm -ne '')) {
			[string]$TimeZone = $Global:GetTimeZone.ShortForm
			[string]$TimeZoneString = "_" + $Global:GetTimeZone.ShortForm
		}
		Else {
			[string]$TimeZoneString = ''
		}
	
	#endregion Determine TimeZone
	
	# DIRECTORIES
	[string]$ResultsTempFolder = $FileDateTime + $TimeZoneString + "_($InputDesc)"
	[string]$ResultsTempPath = Join-Path -Path $ResultsPath -ChildPath $ResultsTempFolder
	[string]$WIPTempFolder = $FileDateTime + $TimeZoneString + "_($InputDesc)"
	[string]$WIPPath = Join-Path -Path $LogPath -ChildPath 'WIP'
	[string]$WIPTempPath = Join-Path -Path $WIPPath -ChildPath $WIPTempFolder

	# FILENAMES
	[string]$ResultsTextFileName = "Test-WSUSClient_Results_" + $FileDateTime + $TimeZoneString + "_($InputDesc).log"
	[string]$ResultsCSVFileName = "Test-WSUSClient_Results_" + $FileDateTime + $TimeZoneString + "_($InputDesc).csv"
	[string]$JobLogFileName = "JobData_" + $FileDateTime + $TimeZoneString + "_($InputDesc).log"

	# PATH + FILENAMES
	[string]$ResultsTextFullName = Join-Path -Path $ResultsPath -ChildPath $ResultsTextFileName
	[string]$ResultsCSVFullName = Join-Path -Path $ResultsPath -ChildPath $ResultsCSVFileName
	[string]$JobLogFullName = Join-Path -Path $JobLogPath -ChildPath $JobLogFileName

#endregion Variables

#region Check Dependencies
	
	# Create Array of Paths to Dependencies to check
#	CLEAR
	$DependencyList = @(
		"$LogPath",
		"$LogPath\History",
		"$LogPath\JobData",
		"$LogPath\Latest",
		"$LogPath\WIP",
		"$HostListPath",
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
	Set-WinTitleBase -ScriptVersion $ScriptVersion 
	[datetime]$ScriptStartTime = Get-Date
	[string]$ScriptStartTimeF = Get-Date -Format g

#endregion Console Start Statements

#region Update Window Title

	Set-WinTitleInput -WinTitleBase $Global:WinTitleBase -InputItem $InputItem
	
#endregion Update Window Title

#region Tasks

	#region Test Connections

		Test-Connections -List $HostList -MaxJobs '25' -TestTimeout '120' -JobmonTimeout '600' -ResultsTextFullName $ResultsTextFullName -JobLogFullName $JobLogFullName -TotalHosts $TotalHosts -DashCount $DashCount -ScriptTitle $ScriptTitle -WinTitleInput $Global:WinTitleInput
		If ($Global:TestConnections.AllFailed -eq $true) {
			# IF TEST CONNECTIONS SUBSCRIPT FAILS UPDATE UI AND EXIT SCRIPT
			Show-ScriptHeader -BlankLines '1' -DashCount $DashCount -ScriptTitle $ScriptTitle
			Write-Host "`r".padright(40,' ') -NoNewline
			Write-Host "`rERROR: ALL SYSTEMS FAILED PERMISSION TEST" -ForegroundColor White -BackgroundColor Red
			Write-Host ''
			Reset-WindowsPatchingUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables
			Break
		}
		ElseIf ($Global:TestConnections.Success -eq $true) {
			[array]$HostList = $Global:TestConnections.PassedList
		}
		Else {
			# IF TEST CONNECTIONS SUBSCRIPT FAILS UPDATE UI AND EXIT SCRIPT
			Show-ScriptHeader -BlankLines '1' -DashCount $DashCount -ScriptTitle $ScriptTitle
			Write-Host "`r".padright(40,' ') -NoNewline
			Write-Host "`rERROR: Test Connection Logic Failed" -ForegroundColor White -BackgroundColor Red
			Write-Host ''
			Reset-WindowsPatchingUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables
			Break
		}
		
	#endregion Test Connections

	#region Job Tasks
	
		Show-ScriptHeader -BlankLines '1' -DashCount $DashCount -ScriptTitle $ScriptTitle

		# STOP AND REMOVE ANY RUNNING JOBS
		Stop-Job *
		Remove-Job *
		
		# SHOULD SHOW ZERO JOBS RUNNING
		Get-JobCount 
		Set-WinTitleJobCount -WinTitleInput $Global:WinTitleInput -JobCount $Global:getjobcount.JobsRunning
	
		# CREATE RESULTS TEMP DIRECTORY
		If ((Test-Path -Path $ResultsTempPath) -ne $true) {
			New-Item -Path $ResultsPath -Name $ResultsTempFolder -ItemType Directory -Force | Out-Null
		}
		
		# CREATE WIP TEMP DIRECTORY
		If ((Test-Path -Path $WIPTempPath) -ne $true) {
			New-Item -Path $WIPPath -Name $WIPTempFolder -ItemType Directory -Force | Out-Null
		}
		
		#Create CSV file with headers
#		Add-Content -Path $ResultsTextFullName -Encoding ASCII -Value 'Hostname,Complete Success,GPO Update Success,Reset-WU Success,Connect Success,Runtime,Starttime,Endtime,Operating System,Host IP,Host Domain,Passed Reg Check,WU Server,WU Status Server,Use WU Server,GPOU ExitCode,Reset-WU ExitCode,Errors,Script Version,Admin Host,User Account'	
		
		# CREATE RESULT TEMP FILE FOR FAILED SYSTEMS
		If ($Global:TestConnections.FailedCount -gt '0') {
			Get-Runtime -StartTime $ScriptStartTime
			[string]$FailedConnectResults = 'False,False,False,False' + ',' + $Global:GetRuntime.Runtime + ',' + $ScriptStartTimeF + ' ' + $TimeZone + ',' + $Global:GetRuntime.EndTimeF + ' ' + $TimeZone + ',' + "Unknown,Unknown,Unknown,Unknown,Unknown,Unknown,Error,Error,Error,Failed Connection" + ',' + $ScriptVersion + ',' + $ScriptHost + ',' + $UserName
			Foreach ($FailedComputerName in ($Global:TestConnections.FailedList)) {
				[string]$ResultsTempFileName = $FailedComputerName + '_Results.log'
				[string]$ResultsTempFullName = Join-Path -Path $ResultsTempPath -ChildPath $ResultsTempFileName
				[string]$ResultsContent = $FailedComputerName + ',' + $FailedConnectResults
				Out-File -FilePath $ResultsTempFullName -Encoding ASCII -InputObject $ResultsContent
			}
		}
		
		#region Job Loop
		
			[int]$HostCount = $HostList.Count
			$i = 0
#			[boolean]$FirstGroup = $false
			Foreach ($ComputerName in $HostList) {
				$TaskProgress = [int][Math]::Ceiling((($i / $HostCount) * 100))
				# Progress Bar
				Write-Progress -Activity "STARTING WSUS SETTINGS TEST JOB ON - ($ComputerName)" -PercentComplete $TaskProgress -Status "OVERALL PROGRESS - $TaskProgress%"
				
				# UPDATE COUNT AND WINTITLE
				Get-JobCount
				Set-WinTitleJobCount -WinTitleInput $Global:WinTitleInput -JobCount $Global:getjobcount.JobsRunning
				# CLEANUP FINISHED JOBS
				Remove-Jobs -JobLogFullName $JobLogFullName

				#region Throttle Jobs
					
					# PAUSE FOR A FEW AFTER THE FIRST 25 ARE QUEUED
#					If (($Global:getjobcount.JobsRunning -ge '20') -and ($FirstGroup -eq $false)) {
#						Sleep -Seconds 5
#						[boolean]$FirstGroup = $true
#					}
				
					While ($Global:getjobcount.JobsRunning -ge $MaxJobs) {
						Sleep -Seconds 5
						Remove-Jobs -JobLogFullName $JobLogFullName
						Get-JobCount
						Set-WinTitleJobCount -WinTitleInput $Global:WinTitleInput -JobCount $Global:getjobcount.JobsRunning
					}
				
				#endregion Throttle Jobs
				
				# Set Job Start Time Used for Elapsed Time Calculations at End ^Needed Still?
				[string]$JobStartTime1 = Get-Date -Format g
#				Add-Content -Path $ScriptLogFullName -Encoding ASCII -Value "JOB STARTED:     ($ComputerName) $JobStartTime1"
				
				#region Background Job

					Start-Job -ScriptBlock {

						#region Job Variables

							# Set Varibles from Argument List
							$ComputerName = $args[0]
							$Assets = $args[1]
							$SubScripts = $args[2]
							$JobLogFullName = $args[3] 
							$ResultsTextFullName = $args[4]
							$ScriptHost = $args[5]
							$UserDomain = $args[6]
							$UserName = $args[7]
							$LogPath = $args[8]
							$ScriptVersion = $args[9]
							$SkipPolicyUpdate = $args[10]
							$SkipSettingsReset = $args[11]
							$UpdateServerURL = $args[12]
							$ResultsTempPath = $args[13]
							$WIPTempPath = $args[14]
							$Timezone = $args[15]

							$testcount = 1
							
							# DATE AND TIME
							$JobStartTimeF = Get-Date -Format g
							$JobStartTime = Get-Date
							
							# NETWORK SHARES
							[string]$RemoteShareRoot = '\\' + $ComputerName + '\C$' 
							[string]$RemoteShare = Join-Path -Path $RemoteShareRoot -ChildPath 'WindowsScriptTemp'
							
							# HISTORY LOG
							[string]$HistoryLogFileName = $ComputerName + '_TestWSUSClient_History.log' 
							[string]$LocalHistoryLogPath = Join-Path -Path $LogPath -ChildPath 'History' 
							[string]$RemoteHistoryLogPath = $RemoteShare 
							[string]$LocalHistoryLogFullName = Join-Path -Path $LocalHistoryLogPath -ChildPath $HistoryLogFileName
							[string]$RemoteHistoryLogFullName = Join-Path -Path $RemoteHistoryLogPath -ChildPath $HistoryLogFileName
														
							# LATEST LOG
							[string]$LatestLogFileName = $ComputerName + '_TestWSUSClient_Latest.log' 
							[string]$LocalLatestLogPath = Join-Path -Path $LogPath -ChildPath 'Latest' 
							[string]$RemoteLatestLogPath = $RemoteShare 
							[string]$LocalLatestLogFullName = Join-Path -Path $LocalLatestLogPath -ChildPath $LatestLogFileName 
							[string]$RemoteLatestLogFullName = Join-Path -Path $RemoteLatestLogPath -ChildPath $LatestLogFileName
							
#							# TEMP WORK IN PROGRESS PATH
#							[string]$WIPPath = Join-Path -Path $LogPath -ChildPath 'WIP'
#							[string]$WIPTempFolder = 
#							[string]$WIPFullName = Join-Path -Path $WIPTempPath -ChildPath $ComputerName
							
							# RESULTS TEMP
							[string]$ResultsTempFileName = $ComputerName + '_Results.log'
							[string]$ResultsTempFullName = Join-Path -Path $ResultsTempPath -ChildPath $ResultsTempFileName
							
							# SCRIPTS
							[string]$ResetWUAFileName = "Reset-WUAService_1.0.0.cmd"
							[string]$RemoteWUScript = Join-Path -Path $RemoteShare -ChildPath $ResetWUAFileName
							[string]$LocalWUScript = Join-Path -Path $SubScripts -ChildPath $ResetWUAFileName
							[string]$ResetWUARemoteCommand = 'C:\WindowsScriptTemp\' + $ResetWUAFileName
							[string]$SeceditMachineRemoteCommand = 'secedit.exe /refreshpolicy machine_policy'
							[string]$SeceditUserRemoteCommand = 'secedit.exe /refreshpolicy user_policy'
							[string]$GpupdateRemoteCommand = 'gpupdate.exe /force'
							
							
							# SET INITIAL JOB SCOPE VARIBLES
							[boolean]$Failed = $false
							[boolean]$CompleteSuccess = $false
#							[boolean]$ConnectionFailed = $false #Used?
							[boolean]$ConnectSuccess = $true

						#endregion Job Variables

						#region Load Sub Functions
						
							Import-Module -Name WindowsPatching -ArgumentList $true
						
						#endregion Load Sub Functions
						
						#region Setup Files and Folders
						
							#region Create WIP File
							
								If ((Test-Path -Path "$WIPTempPath\$ComputerName") -eq $false) {
									New-Item -Item file -Path "$WIPTempPath\$ComputerName" -Force | Out-Null
								}
							
							#endregion Create WIP File
							
							#region Create Remote Temp Folder
							
								If ((Test-Path -Path $RemoteShare) -eq $False) {
									New-Item -Path $RemoteShareRoot -name WindowsScriptTemp -ItemType Directory -Force | Out-Null
								}
							
							#endregion Create Remote Temp Folder
							
							#region Temp: Remove Old Remote Computer Windows-Patching Directory
						
								If ((Test-Path -Path "$RemoteShareRoot\Windows-Patching") -eq $true) {
									If ((Test-Path -Path "$RemoteShareRoot\Windows-Patching\*.log") -eq $true) {
										Copy-Item -Path "$RemoteShareRoot\Windows-Patching\*.log" -Destination $RemoteShare -Force
									}
									Remove-Item -Path "$RemoteShareRoot\Windows-Patching" -Recurse -Force
								}
						
							#endregion Temp: Remove Old Remote Computer Windows-Patching Directory
							
							#region Temp: Remove Old Remote Computer WindowsPatching Directory
						
								If ((Test-Path -Path "$RemoteShareRoot\WindowsPatching") -eq $true) {
									If ((Test-Path -Path "$RemoteShareRoot\WindowsPatching\*.log") -eq $true) {
										Copy-Item -Path "$RemoteShareRoot\WindowsPatching\*.log" -Destination $RemoteShare -Force
									}
									Remove-Item -Path "$RemoteShareRoot\WindowsPatching" -Recurse -Force
								}
						
							#endregion Temp: Remove Old Remote Computer WindowsPatching Directory
							
							#region Temp: Remove Old Remote Computer WindowsScriptsTemp Directory
						
								If ((Test-Path -Path "$RemoteShareRoot\WindowsScriptsTemp") -eq $true) {
									If ((Test-Path -Path "$RemoteShareRoot\WindowsScriptsTemp\*.log") -eq $true) {
										Copy-Item -Path "$RemoteShareRoot\WindowsScriptsTemp\*.log" -Destination $RemoteShare -Force
									}
									Remove-Item -Path "$RemoteShareRoot\WindowsScriptsTemp" -Recurse -Force
								}
						
							#endregion Temp: Remove Old Remote Computer WindowsScriptsTemp Directory

							#region Temp: Remove Old Files
							
								$filepaths = @(
									"\\$ComputerName\c$\WindowsScriptTemp\WUReset_1.0.0.cmd"
# 									("\\$ComputerName\c$\WindowsScriptTemp\" + $ComputerName + '_LastPatch.log')
								)
								# Remove each item in the filepaths array if exists
								ForEach ($filepath in $filepaths) {
									If ((Test-Path -Path $filepath) -eq $true) {
										Remove-Item -Path $filepath -Force 
									}
								}
								
							#endregion Temp: Remove Old Files
						
							#region Temp: Rename Old Logs
							
								$OldHistoryFileFullName = '\\' + $ComputerName + '\c$\WindowsScriptTemp\' + $ComputerName + '_WSUSCheck.log'
								If ((Test-Path -Path $OldHistoryFileFullName) -eq $true) {
									Rename-Item -Path $OldHistoryFileFullName -NewName $HistoryLogFileName -Force
								}
							
							#endregion Temp: Rename Old Logs
							
							#region Add Script Log Header
							
								$DateTimeF = Get-Date -format g
								$ScriptLogData = @()
								$ScriptLogData += @(
									'',
									'',
									'*******************************************************************************************************************',
									'*******************************************************************************************************************',
									"JOB STARTED: $DateTimeF $Timezone",
									"SCRIPT VER:  $ScriptVersion",
									"ADMINUSER:   $UserDomain\$UserName",
									"SCRIPTHOST:  $ScriptHost"
								)
							
							#endregion Add Script Log Header
							
						#endregion Setup Files and Folders
						
						#region Gather Remote System Information
						
							#region Get Hard Drive Space
							
								[int]$MinFreeMB = '10'
								# C: DRIVE SPACE CHECK USER ENTERED VALUE
								Get-DiskSpace -ComputerName $ComputerName -MinFreeMB $MinFreeMB
								# ADD RESULTS TO SCRIPT LOG ARRAY
								$Results = $null
								$Results = ($Global:GetDiskSpace | Format-List | Out-String).Trim('')
								$ScriptLogData += @(
									'',
									'GET C: DRIVE SPACE',
									'-------------------',
									"$Results"
								)
								
								# DETERMINE RESULTS
								If ($Global:GetDiskSpace.Success -eq $true) {
									If ($Global:GetDiskSpace.Passed -eq $true) {
										[Boolean]$DiskSpaceOK = $true
									}
									Else {
										[boolean]$Failed = $true
										[boolean]$DiskSpaceOK = $false
										[string]$ScriptErrors += "Less Than Minimum Drive Space. "
									}
									# SET RESULT VARIABLES
#									[string]$FreeSpace = $Global:GetDiskSpace.FreeSpaceMB
#									[string]$DriveSize = $Global:GetDiskSpace.DriveSize
									
									# DETERMINE RESULTS FOR LOG MIN SPACE
									If (($Global:GetDiskSpace.FreeSpaceMB) -ge '5') {
										[boolean]$LogDiskSpaceOK = $true
									}
									Else {
										[boolean]$LogDiskSpaceOK = $false
										[string]$ScriptErrors += "Not Enough Disk Space for Logs. "
									}
								}
								Else {
									[boolean]$DiskSpaceOK = $false
									[boolean]$LogDiskSpaceOK = $false
#									[string]$FreeSpace = 'N/A'
#									[string]$DriveSize = 'N/A'
									[boolean]$Failed = $true
									[string]$ScriptErrors += $Global:GetDiskSpace.Notes
								}
									
							#endregion Get Hard Drive Space
						
							#region Get OS Version
							
								# ^NEED TO ADD ALTCREDS LOGIC
								Get-OSVersion -ComputerName $ComputerName -SkipVimQuery
								# ADD RESULTS TO SCRIPT LOG ARRAY
								$Results = $null
								[array]$Results = ($Global:GetOSVersion | Format-List | Out-String).Trim('')
								$ScriptLogData += @(
									'',
									'GET OS VERSION',
									'---------------',
									"$Results"
								)
								If ($Global:GetOSVersion.Success -eq $true) {
									[string]$OSVersionShortName = $Global:GetOSVersion.OSVersionShortName
									[string]$OSArch = $Global:GetOSVersion.OSArch
									[string]$OSVersion = $Global:GetOSVersion.OSVersion
								}
								Else {
									[string]$OSVersionShortName = 'Error'
									[string]$OSArch = 'Error'
									[string]$OSVersion = 'Error'
								}
								
								
							#endregion Get OS Version
							
							#region Get Host Domain
								
								Get-HostDomain -ComputerName $ComputerName -SkipVimQuery
								# ADD RESULTS TO SCRIPT LOG ARRAY
								$Results = $null
								[array]$Results = ($Global:gethostdomain | Format-List | Out-String).Trim('')
								$ScriptLogData += @(
									'',
									'GET HOST DOMAIN',
									'----------------',
									"$Results"
								)
								If ($Global:GetHostDomain.Success -eq $true) {
									[string]$HostDomain = $Global:GetHostDomain.HostDomain
								}
								Else {
									[string]$HostDomain = 'Error'
								}
								
							#endregion Get Host Domain
							
							#region Get HOST IP
								
								Get-HostIP -ComputerName $ComputerName -SkipVimQuery
								# ADD RESULTS TO SCRIPT LOG ARRAY
								$Results = $null
								[array]$Results = ($Global:GetHostIP | Format-List | Out-String).Trim('')
								$ScriptLogData += @(
									'',
									'GET HOST IP',
									'------------',
									"$Results"
								)
								If ($Global:GetHostIP.Success -eq $true) {
									[string]$HostIP = $Global:GetHostIP.HostIP
								}
								Else {
									[string]$HostIP = 'Error'
								}
								
							#endregion Get HOST IP
						
						#endregion Gather Remote System Information
						
						#region Main Tasks
						
							If ($DiskSpaceOK -eq $true) {
							
								#region Get WUInfo
									
									Get-WUInfo -ComputerName $ComputerName -Assets $Assets -UpdateServerURL $UpdateServerURL 
									If ($Global:GetWUInfo.Success -eq $true) {
										[string]$WuServer = $Global:GetWUInfo.WUServer
										[string]$WuStatusServer = $Global:GetWUInfo.WUStatusServer
										[boolean]$PassedRegAudit = $Global:GetWUInfo.WUServerOK
										[string]$UseWuServer = $Global:GetWUInfo.UseWUServer
									}
									Else {
										[boolean]$Failed = $true
										[string]$WuServer = 'Error'
										[string]$WuStatusServer = 'Error'
										[string]$PassedRegAudit = 'Error'
										[string]$UseWuServer = 'Error'
									}
									# ADD RESULTS TO SCRIPT LOG ARRAY
									$Results = $null
									[array]$Results = ($Global:GetWUInfo | Format-List | Out-String).Trim('')
									$ScriptLogData += @(
										'',
										'GET WINDOWS UPDATE INFO',
										'-----------------------',
										"$Results"
									)

								#endregion Get WUInfo
								
								#region GPO Update

									# RUN GPO UPDATE IF SELECTED
									If ($SkipPolicyUpdate.IsPresent -eq $false) {
										# UPDATE HISTORY LOGS
										If ($Global:GetOSVersion.Success -eq $true) {
											# REFRESH GROUP POLICIES BASED ON OS
											IF (($Global:GetOSVersion.OSVersionShortName -eq '2000') -or ($Global:GetOSVersion.OSVersionShortName -eq 'XP')-or ($Global:GetOSVersion.OSVersionShortName -eq 'NT')) {
												# RUN SECEDIT ON REMOTE HOST FOR MACHINE POLICY
												Invoke-PSExec -ComputerName $ComputerName -Assets $Assets -Timeout '600' -RemoteCommand $SeceditMachineRemoteCommand
												
												# ADD RESULTS TO SCRIPT LOG ARRAY
												$Results = $null
												[array]$Results = ($Global:InvokePSExec | Format-List | Out-String).Trim('')
												$ScriptLogData += @(
													'',
													'Invoke-PSExec SECEDIT MACHINE UPDATE GPOUPDATE',
													'-------------------------------------------',
													"$Results"
												)
												
												$GPOUpdateExitCode = $Global:InvokePSExec.ExitCode
												If ($Global:InvokePSExec.Success -eq $true) {
													[boolean]$GPOUpdateSuccess = $true
												}
												Else {
													[boolean]$Failed = $true
													[boolean]$GPOUpdateSuccess = $false
												}
												# RUN SECEDIT ON REMOTE HOST FOR USER POLICY
												Invoke-PSExec -ComputerName $ComputerName -Assets $Assets -Timeout '600' -RemoteCommand $SeceditUserRemoteCommand
																						
												# ADD RESULTS TO SCRIPT LOG ARRAY
												$Results = $null
												[array]$Results = ($Global:InvokePSExec | Format-List | Out-String).Trim('')
												$ScriptLogData += @(
													'',
													'Invoke-PSExec SECEDIT USER POLICY GPOUPDATE',
													'----------------------------------------',
													"$Results"
												)
												
												$GPOUpdateExitCode = $Global:InvokePSExec.ExitCode
												If ($Global:InvokePSExec.Success -eq $true) {
													[boolean]$GPOUpdateSuccess = $true
												}
												Else {
													[boolean]$Failed = $true
													[boolean]$GPOUpdateSuccess = $false
												}
											}
											Else {
												# RUN GPUPDATE ON REMOTE HOST
												Invoke-PSExec -ComputerName $ComputerName -Assets $Assets -Timeout '600' -RemoteCommand $GpupdateRemoteCommand
												
												# ADD RESULTS TO SCRIPT LOG ARRAY
												$Results = $null
												[array]$Results = ($Global:InvokePSExec | Format-List | Out-String).Trim('')
												$ScriptLogData += @(
													'',
													'Invoke-PSExec GPUPDATE',
													'-------------------',
													"$Results"
												)
												
												$GPOUpdateExitCode = $Global:InvokePSExec.ExitCode
												If ($Global:InvokePSExec.Success -eq $true) {
													[boolean]$GPOUpdateSuccess = $true
												}
												Else {
													[boolean]$Failed = $true
													[boolean]$GPOUpdateSuccess = $false
												}									
											}
										}
										Else {
											[boolean]$GPOUpdateSuccess = $false
										}
									}
									
								#endregion GPO Update
								
								#region WU Reset

									If ($SkipSettingsReset.IsPresent -eq $false) {
										# IF RESET-WUAService.CMD IS MISSING THEN COPY TO CLIENT
										If ((Test-Path -Path $RemoteWUScript) -eq $False) {
											Copy-Item -Path $LocalWUScript -Destination $RemoteShare | Out-Null 
										}
										
										# RESTART WINDOWS UPDATE SERVICE ON CLIENT WITH BATCH FILE
										Invoke-PSExec -ComputerName $ComputerName -Assets $Assets -Timeout '600' -RemoteCommand $ResetWUARemoteCommand
										
										# ADD RESULTS TO SCRIPT LOG ARRAY
										$Results = $null
										[array]$Results = ($Global:InvokePSExec | Format-List | Out-String).Trim('')
										$ScriptLogData += @(
											'',
											'Invoke-PSExec Run Reset-WUSettings.cmd',
											'--------------------------------------',
											"$Results"
										)

										
										$ResetWUAExitCode = $Global:InvokePSExec.ExitCode
										If ($Global:InvokePSExec.Success -eq $true) {
											[boolean]$ResetWUASuccess = $true
										}
										Else {
											[boolean]$Failed = $true
											[boolean]$ResetWUASuccess = $false
										}
									} #/If WURest Option = Yes

								#endregion WU Reset
							
							}
						
						#endregion Main Tasks
						
						#region Generate Report
							
							#region Determine Results
							
								If ($Failed -eq $false) {
									[boolean]$CompleteSuccess = $true
								}
								Else {
									[boolean]$CompleteSuccess = $false
								}
							
							#endregion Determine Results
							
							#region Set Results if Missing
							
								If (!$OSVersion) {
									[string]$OSVersion = 'Unknown'
								}
								If (!$HostIP) {
									[string]$HostIP = 'Unknown'
								}
								If (!$HostDomain) {
									[string]$HostDomain = 'Unknown'
								}							
								If (!$ScriptErrors) {
									[string]$ScriptErrors = 'None'
								}
								# Unique to cmdlet
								If (!$WuServer) {
									[string]$WuServer = 'Unknown'
								}
								If (!$WuStatusServer) {
									[string]$WuStatusServer = 'Unknown'
								}
								If (!$UseWuServer) {
									[string]$UseWuServer = 'Unknown'
								}
								If (!$OSVersionShortName) {
									[string]$OSVersionShortName = 'Unknown'
								}
								If (!$GPOUpdateSuccess) {
									[string]$GPOUpdateSuccess = 'N/A'
								}
								If (!$ResetWUASuccess) {
									[string]$ResetWUASuccess = 'N/A'
								}
								If (!$PassedRegAudit) {
									[string]$PassedRegAudit = 'N/A'
								}
								If (!$GPOUpdateExitCode) {
									[string]$GPOUpdateExitCode = 'N/A'
								}
								If (!$ResetWUAExitCode) {
									[string]$ResetWUAExitCode = 'N/A'
								}
							
							#endregion Set Results if Missing
							
							#region Output Results to File
							
								Get-Runtime -StartTime $JobStartTime #Results used for History Log Footer too
								[string]$TaskResults = $ComputerName + ',' + $CompleteSuccess + ',' + $GPOUpdateSuccess + ',' + $ResetWUASuccess + ',' + $ConnectSuccess + ',' + $Global:GetRuntime.Runtime + ',' + $JobStartTimeF + ' ' + $TimeZone + ',' + $Global:GetRuntime.EndTimeF + ' ' + $TimeZone + ',' + $OSVersion + ',' + $HostIP + ',' + $HostDomain + ',' + $PassedRegAudit + ',' + $WuServer + ',' + $WuStatusServer + ',' + $UseWuServer + ',' + $GPOUpdateExitCode + ',' + $ResetWUAExitCode + ',' + $ScriptErrors + ',' + $ScriptVersion + ',' + $ScriptHost + ',' + $UserName
								
								[int]$LoopCount = 0
								[boolean]$ErrorFree = $false
								DO {
									$LoopCount++
									Try {
										Out-File -FilePath $ResultsTempFullName -Encoding ASCII -InputObject $TaskResults -ErrorAction Stop
										[boolean]$ErrorFree = $true
									}
									# IF FILE BEING ACCESSED BY ANOTHER SCRIPT CATCH THE TERMINATING ERROR
									Catch [System.IO.IOException] {
										[boolean]$ErrorFree = $false
										Sleep -Milliseconds 500
										# Could write to ScriptLog which error is caught
									}
									# ANY OTHER EXCEPTION
									Catch {
										[boolean]$ErrorFree = $false
										Sleep -Milliseconds 500
										# Could write to ScriptLog which error is caught
									}
								}
								# Try until writes to output file or 
								Until (($ErrorFree -eq $true) -or ($LoopCount -ge '150'))
							
							#endregion Output Results to File
							
							#region Add Script Log Footer
							
								$Runtime = $Global:GetRuntime.Runtime
								$DateTimeF = Get-Date -format g
								$ScriptLogData += @(
									'',
									'',
									'',
									"COMPLETE SUCCESS: $CompleteSuccess",
									'',
									"JOB:             [ENDED] $DateTimeF $Timezone",
									"Runtime:         $Runtime",
									'---------------------------------------------------------------------------------------------------------------------------------',
									''
								)
							
							#endregion Add Script Log Footer
							
							#region Write Script Logs
							
								If ($LogDiskSpaceOK -eq $true) {
									Add-Content -Path $LocalHistoryLogFullName,$RemoteHistoryLogFullName -Encoding ASCII -Value $ScriptLogData
									Out-File -FilePath $LocalLatestLogFullName -Encoding ASCII -Force -InputObject $ScriptLogData
									Out-File -FilePath $RemoteLatestLogFullName -Encoding ASCII -Force -InputObject $ScriptLogData
								}
								Else {
									Add-Content -Path $LocalHistoryLogFullName -Encoding ASCII -Value $ScriptLogData
									Out-File -FilePath $LocalLatestLogFullName -Encoding ASCII -Force -InputObject $ScriptLogData
								}
							
							#endregion Write Script Logs
						
						#endregion Generate Report
						
						#region Remove WIP File
						
							If ((Test-Path -Path "$WIPTempPath\$ComputerName") -eq $true) {
								Remove-Item -Path "$WIPTempPath\$ComputerName" -Force
							}
						
						#endregion Remove WIP File


					} -ArgumentList $ComputerName,$Assets,$SubScripts,$JobLogFullName,$ResultsTextFullName,$ScriptHost,$UserDomain,$UserName,$LogPath,$ScriptVersion,$SkipPolicyUpdate,$SkipSettingsReset,$UpdateServerURL,$ResultsTempPath,$WIPTempPath,$Timezone | Out-Null
					
				#endregion Background Job
				
				# PROGRESS COUNTER
				$i++
			} #/Foreach Loop
		
		#endregion Job Loop

		Show-ScriptHeader -BlankLines '4' -DashCount $DashCount -ScriptTitle $ScriptTitle
		Show-ScriptStatusJobsQueued -JobCount $Global:TestConnections.PassedCount
		
	#endregion Job Tasks

	#region Job Monitor

		Get-JobCount
		Set-WinTitleJobCount -WinTitleInput $Global:WinTitleInput -JobCount $Global:getjobcount.JobsRunning
		
		# Job Monitoring Function Will Loop Until Timeout or All are Completed
		Watch-Jobs -JobLogFullName $JobLogFullName -Timeout $JobQueTimeout -Activity "TESTING WSUS SETTINGS" -WinTitleInput $Global:WinTitleInput
		
	#endregion Job Monitor

#endregion Tasks

#region Cleanup WIP

	# GATHER LIST AND CREATE RESULTS FOR COMPUTERNAMES LEFT IN WIP
	If ((Test-Path -Path "$WIPTempPath\*") -eq $true) {
		Get-Runtime -StartTime $ScriptStartTime
		[string]$TimedOutResults = 'False,False,False,False' + ',' + $Global:GetRuntime.Runtime + ',' + $ScriptStartTimeF + ' ' + $TimeZone + ',' + $Global:GetRuntime.EndTimeF + ' ' + $TimeZone + ',' + "Unknown,Unknown,Unknown,Unknown,Unknown,Unknown,Error,Error,Error,Timed Out" + ',' + $ScriptVersion + ',' + $ScriptHost + ',' + $UserName

		$TimedOutComputerList = @()
		$TimedOutComputerList += Get-ChildItem -Path "$WIPTempPath\*"
		Foreach ($TimedOutComputerObject in $TimedOutComputerList) {
			[string]$TimedOutComputerName = $TimedOutComputerObject | Select-Object -ExpandProperty Name
			[string]$ResultsContent = $TimedOutComputerName + ',' + $TimedOutResults
			[string]$ResultsFileName = $TimedOutComputerName + '_Results.log'
			Out-File -FilePath "$ResultsTempPath\$ResultsFileName" -Encoding ASCII -InputObject $ResultsContent
			Remove-Item -Path ($TimedOutComputerObject.FullName) -Force
		}
	}
	
	# REMOVE WIP TEMP DIRECTORY
	If ((Test-Path -Path $WIPTempPath) -eq $true) {
			Remove-Item -Path $WIPTempPath -Force -Recurse
	}

#endregion Cleanup WIP

#region Convert Output Text Files to CSV

	# CREATE RESULTS CSV
	[array]$Header = @(
		"Hostname",
		"Complete Success",
		"GPO Update Success",
		"Reset-WU Success",
		"Connect Success",
		"Runtime",
		"Starttime",
		"Endtime",
		"Operating System",
		"Host IP",
		"Host Domain",
		"Passed Reg Check",
		"WU Server",
		"WU Status Server",
		"Use WU Server",
		"GPOU ExitCode",
		"Reset-WU ExitCode",
		"Errors",
		"Script Version",
		"Admin Host",
		"User Account"
	)
	[array]$OutFile = @()
	[array]$ResultFiles = Get-ChildItem -Path $ResultsTempPath
	Foreach ($FileObject in $ResultFiles) {
		[array]$OutFile += Import-Csv -Delimiter ',' -Path $FileObject.FullName -Header $Header
	}
	$OutFile | Export-Csv -Path $ResultsCSVFullName -NoTypeInformation -Force

	# DELETE TEMP FILES AND DIRECTORY
	## IF CSV FILE WAS CREATED SUCCESSFULLY THEN DELETE TEMP
	If ((Test-Path -Path $ResultsCSVFullName) -eq $true) {
		If ((Test-Path -Path $ResultsTempPath) -eq $true) {
			Remove-Item -Path $ResultsTempPath -Force -Recurse
		}
	}

#endregion Convert Output Text Files to CSV

#region Script Completion Updates

	Show-ScriptHeader -BlankLines '1' -DashCount $DashCount -ScriptTitle $ScriptTitle
	Get-Runtime -StartTime $ScriptStartTime
	Show-ScriptStatusRuntimeTotals -StartTimeF $ScriptStartTimeF -EndTimeF $Global:GetRuntime.EndTimeF -Runtime $Global:GetRuntime.Runtime
	[int]$TotalHosts = $Global:TestPermissions.PassedCount
	Show-ScriptStatusTotalHosts -TotalHosts $TotalHosts
	Show-ScriptStatusFiles -ResultsPath $ResultsPath -ResultsFileName $ResultsCSVFileName -LogPath $LogPath
	
	If ($Global:WatchJobs.JobTimeOut -eq $true) {
		Show-ScriptStatusJobLoopTimeout
		Set-WinTitleJobTimeout -WinTitleInput $Global:WinTitleInput
	}
	Else {
		Show-ScriptStatusCompleted
		Set-WinTitleCompleted -WinTitleInput $Global:WinTitleInput
	}

#endregion Script Completion Updates

#region Display Report
	
	If ($SkipOutGrid.IsPresent -eq $false) {
		$OutFile | Out-GridView -Title "Test WSUS Client Results for $InputItem"
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
	Remove-Jobs
	Get-JobCount
	Get-HostDomain
	Get-HostIP
	Get-WUInfo
	Watch-Jobs
	Invoke-PSExec
	Reset-WindowsPatchingUI
	Show-ScriptHeader
	MultiStopWatch
	Test-Connections
	MultiSet-WinTitle
	MultiOut-ScriptLog
	MultiShow-Script-Status
	Reset-WUSettings.cmd
#>

<# TO DO
	1. Fix up and improve script and job logging
	2. Rewrite Reset-WUSettings.cmd logic
	3. Added error handling to GPO Update and WU Reset
#>

<# Change Log
2.0.3 - 01/31/2012
	Created.
	Complete rewrite to new format
2.0.4 - 02/01/2012
	Stable
2.0.5 - 02/01/2012
	Added missing failed varible set to false to fix complete success output
	Added HostDomain subscript and sections
	Moved OS Version and HostIP var set right after running functions
2.0.6 - 02/01/2012
	Fixed order for Runtime, Startime to be correct on output.
2.0.7 - 02/01/2012
	Changed HostIP out to logs variable to correct one (Copy/Paste error)
2.0.8 - 02/02/2012
	Added missing WIP file removal to end of job loop
2.0.9 - 02/02/2012
	Converted Test Permissions Section to Subscript Function
2.1.0 - 02/02/2012
	Tweaks with Test-Connections parameters
2.1.1 - 02/02/2012
	Bumped MaxJobs for Test-Connections to 100
	Bumped MaxJobs for parent script to 200
2.1.2 - 02/03/2012
	Bumped MaxJobs for Test-Connections to 500
	Added separater Line with Header of History Logs
2.1.3 - 02/03/2012
	Changed Failedlog to FailedAccessLog
2.1.4 - 02/03/2012
	Found a limit of about 250 background jobs.
	Going to try and add some sleep and slow down the job creations to see if it can
	do more if fed slower.
2.1.5 - 02/03/2012
	Added Try/Catch to Output file in Job Loop incase file is locked by other job writing to it
2.1.6 - 02/04/2012
	Fixed mix up of currenthost and ScriptHost
	Fixed JobTimeOut Out-ScriptLog-JobTimeout parameters
	Update to MultiOut-ScriptLog_1.0.2
	Fixed issue if using List as input. Basically limited the Wintitle and filename to two hosts 
	from the List.
2.1.7 - 02/04/2012
	Combined Timeout and Completed at end so CSV is generated either way.
	Increased Monitor Jobs Timeout to 15 minutes.
	Increased MaxJobs to 1000
	Increased MaxJobs for Test-connections to 500
2.1.8 - 02/07/2012
	Updated to MultiSet-WinTitle_1.0.3
	Added dotnetversion Set-WinTitleBase
	Changed parameter from psver to psversion for Set-WinTitleBase
	Added spaces at end of Show-ScriptHeader so the new Progress Bars doesn't cover up the UI updates
	Changed Set-WinTitleNotice to Set-WinTitleStart
	Added .ToUpper() for $ComputerName filename set
2.1.9 - 02/08/2012
	Added $ErrorActionPreference = "Inquire" temp for debugging missed error handling
	Working on error handling and validaiton for PSExec
2.2.0 - 02/08/2012
	Changed GPOUPDATE section to use batch file
2.2.1 - 02/09/2012
	Adding GPUPDATE.cmd and SECRESET.cmd
2.2.2 - 02/09/2012
	Changed OSVersionShortName variable from local to global Get-OSVersion PSObject Output
2.2.3 - 02/09/2012 (Stable)
	Removed GPUPDATE_1.cmd and SECRESET_1.cmd
	Updated to Invoke-PSExec_1.0.3
	Fixed up GPOUpdate section to match Invoke-PSExec 1.0.3
2.2.4 - 02/09/2012
	Converted RegAudit section to used Get-WUInfo_1.0.0
2.2.5 - 02/09/2012
	Cleaned up code
	Changed WUReset_1.cmd back to WUReset.cmd
2.2.6 - 02/10/2012
	Updated to Invoke-PSExec_1.0.4
2.2.6 - 02/10/2012
	Updated to Invoke-PSExec_1.0.5 (Try/Catch)
	Added datetime to some history log updates
2.2.9 - 04/16/2012
	Changed Version Scheme
	Changed log file formatting
	Added Show-ScriptHeader
	Changed Show-ScriptHeader lines to have parameters for Function
2.3.0 - 04/20/2012
	Switched to Fun_Invoke-PSExec_1.0.6 for parameter name changes
	Switched to Get-WUInfo_1.0.1
2.3.1 - 04/20/2012
	Added Progress Bar for Queing Jobs
2.3.2 - 04/23/2012
	Tons more renames and case changes
	Changed to latest SubScripts
	Changed all the History logging to be stored in an array and output to the files once at the end.
2.3.3 - 04/26/2012
	Changed to Function and placed in WindowsPatching Module
	Several sub script renames
	Added cleanup to end
2.3.4 - 04/27/2012
	Changed Cleanup Section to Reset-WindowsPatchingUI subscript.
	Added SkipGrid switch parameter
2.3.6 - 05/02/2012
	Added FileBrowser option
2.3.7 - 05/03/2012
	Changed folder locations and some names using Set-WindowsPatchingDefault Global variable.
	Changed Windows-Patching to WindowsPatching remote folder
	Added remove / copy logs of Windows-Patching folder on remote system
	Renamed a lot of variables so they make more since and continued improvement on my own stardards
	Fixed some rename mistakes
	Changed Set-Header to Show-ScriptHeader
	Added Out-ScriptLog-Errors specifically for writing $Error to log, may not need it
	Added Show-ScriptStatusFiles function to give path to output files and folders
	Changed name of WUReset.cmd to WUReset_1.0.0.cmd
2.3.8 - 05/07/2012
	Renamed Get-FileName to Get-FileName and moved to SubScripts
	Changed the module to not load Get-FileName and have the scripts call it if needed.
	Moved GPO Success and WUReset Success to front of results
2.3.9 - 05/08/2012
	Fixed Get-OSVersion Function load to correct version 1.0.8
	Added Logic for the SkipAllVmware for Get-OSVersion
	Added Logic for the SkipAllVmware for Get-HostDomain
	Added Logic for the SkipAllVmware for Get-HostIP
	Added JobQueTimeout parameter
	Turned down MaxJobs default. having issues with over 500 currently.
	Tweaked the Maxjobs and JobQueTimeouts to be more efficient
	Added Remove-Jobs to each loop to maintain a better Jobs Left nummber and stay out of the Job Throttle loop more.
	Added WIP file cleanup for it Watch-Jobs Timeout.
	Switched to Test-Connections 1.0.4
	Switched to Watch-Jobs 1.0.3
	Added Get-TimeZone to pull localhost timezone for file names.
2.4.0 - 05/10/2012
	Renamed Reset-UI to Reset-WindowsPatchingUI
	Added vCenter and Alt VIM Creds Prompts
	Added missing SkipAllVmware logic to job
2.4.1 - 05/11/2012
	Fixed Prompt for AltViCreds. It needed to be outside Missing Host Vmware Prompt Group.
2.4.2 - 05/14/2012
	Switched to Show-WindowsPatchingTip 1.0.2
2.4.2 - 05/15/2012
	Added Hosts that failed connection test to Results.
	Added Latest Log output
	Renamed History Log
	Renamed WUReset to Reset-WUSettings
	Renamed more variables with upper and lower case
2.4.3 - 05/16/2012
	Switched to Get-OSVersion 1.0.9
	Removed FailedAccess logic now that it's in the results.
	Switched to Test-Connections 1.0.6
2.4.4 - 07/25/2012
	Removed duplicate $SubScript argument to job loop.
	Fixed missing comma before $LogPath job argument.
2.4.5 - 07/27/2012
	Added check disk space logic because logs are wrote to the remote system and would bomb the script if drive was full.
2.4.6 - 07/30/2012
	Switched to Invoke-PSExec 1.0.8
2.4.6 - 08/06/2012
	Switched to Get-OSVersion 1.1.0
	Switched to Test-Connections 1.0.7
2.4.7 - 08/08/2012
	Added two missing column data for if system failed connection.
2.4.8 -
2.4.9 - 10/22/2012
	Switched to Reset-WindowsPatchingUI 1.0.3
2.5.0 - 11/27/2012
	Removed FileName Parameter
	Changed WindowsScriptsTemp to WindowsScriptTemp
2.5.1 - 12/04/2012
	Switched to Test-Connection 1.0.8
	Changed logic for if all systems fail connection test it will reset the UI
2.5.2 - 12/13/2012
	Switched to Invoke-PSExec 1.0.9
	Changed the way the output logs are wrote to avoid the issue of background jobs
		competing over writing to one file. Now a temp folder is created and each job
		writes it's own results log and then at the end they are all pulled together into
		one final CSV results log.
	Changed the WIP file to go to it's own temp folder just like the results logs.
		This seperates them if multiple instances of the script are ran at the same
		time. Then I can pull the computernames left over if the script times out and
		add them to the results.
	Added StopWatch Subscript at this level and not just in the Watch-Jobs subscript
	Added Start-StopWatch to get full script runtime instead of starting after all the
		jobs are queued once under the throttle limit.  Which then will include the
		time for the Test-Connections section etc.
	Switched to Watch-Jobs 1.0.4
	Switched to MultiStopWatch 1.0.2
2.5.3 - 12/14/2012
	Removed all Vmware items.
	Switched to Test-Connections 1.0.9
2.5.4 - 12/17/2012
	Added better logic to Get-DiskSpace section
	Tons of code cleanup and region additions
2.5.5 - 12/18/2012
	Added Reset UI before breaks/returns
	Reworked the Dependency check section.
2.5.6 - 12/26/2012
	Switched to Remove-Jobs 1.0.6
	Switched to Watch-Jobs 1.0.5
	Rewrote Get Hard Drive section. Changed to two variables to condition on 
		DiskSpaceOK and LogDiskSpaceOK
2.5.7 - 12/28/2012
	Removed Dot sourcing subscripts and load all when module is imported.
	Changed Show-ScriptStatus functions to not have second hypen in name.
	Changed Set-WinTitle functions to not have second hypen in name.
	Removed -SubScript parameter from all subfunction calls.
	Removed dot sourcing subscripts because all are loaded when the module is imported now.
	Removed dependency check for subscripts.
	Added Import WindowsPatching Module to Background jobs.
	Removed Runas 32-bit from background jobs.
	Added Timezone argument passthrough to background jobs for logs.
2.5.8 - 01/09/2013
	Added Timezone to result start and end times.
2.5.9 - 01/14/2013
	Renamed WPM to WindowsPatching
2.6.0 - 01/18/2013
	Added WsusGroups, UpdateServer and WsusPort Parameters plus logic to handle it.
		This can eliminate the need of making text file lists and just test a specific 
		WSUS group or groups.
	Renamed HostInputDesc to InputDesc
2.6.1 - 01/23/2013
	Renamed WsusPort to UpdateServerPort
	Added UpdateServerPort default grab from Module Defaults if missing
#>


#endregion Notes
