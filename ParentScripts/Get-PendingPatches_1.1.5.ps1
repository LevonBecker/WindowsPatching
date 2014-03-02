#requires –version 2.0

Function Get-PendingPatches {

#region Help

<#
.SYNOPSIS
	Check remote computer for pending Windows Updates.
.DESCRIPTION
	Check remote computer for pending Windows Updates.
.NOTES
	VERSION:    1.1.5
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
	%USERPROFILE%\Documents\Results\Get-PendingPatches
	
	LOGS
	%USERPROFILE%\Documents\Logs\Get-PendingPatches
	+---History
	+---JobData
	+---Latest
	+---WIP
.EXAMPLE
	Get-PendingPatches -ComputerName server01 
	Patch a single computer.
.EXAMPLE
	Install-Patches server01 
	Patch a single computer.
	The ComputerName parameter is in position 0 so it can be left off for a
	single computer.
.EXAMPLE
	Get-PendingPatches -List server01,server02
	Test a list of hostnames comma separated without spaces.
.EXAMPLE
	Get-PendingPatches -List $MyHostList 
	Test a list of hostnames from an already created array variable.
	i.e. $MyHostList = @("server01","server02","server03")
.EXAMPLE
	Get-PendingPatches -FileBrowser 
	This switch will launch a separate file browser window.
	In the window you can browse and select a text or csv file from anywhere
	accessible by the local computer that has a list of host names.
	The host names need to be listed one per line or comma separated.
	This list of system names will be used to perform the script tasks for 
	each host in the list.
.EXAMPLE
	Get-PendingPatches -FileBrowser -SkipOutGrid
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
	Get-PendingPatches -WsusGroups group01 
	This will query the WSUS Server for a list of hostnames in a single or
	multiple WSUS groups to run the script against.
	This is an array so more than one can be listed as a comma seperated list
	without spaces.
.EXAMPLE
	Get-PendingPatches -WsusGroups group01,group02,group03 
	This will query the WSUS Server for a list of hostnames in a single or
	multiple WSUS groups to run the script against.
	This is an array so more than one can be listed as a comma seperated list
	without spaces.
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
	Default = 250
.PARAMETER JobQueTimeout
	Maximum amount of time in seconds to wait for the background jobs to finish 
	before timing out. 	Adjust this depending out the speed of your environment 
	and based on the maximum jobs ran simultaneously.
	
	If the MaxJobs setting is turned down, but there are a lot of servers this 
	may need to be increased.
	
	This timer starts after all jobs have been queued.
	Default = 1800 (30 minutes)
.PARAMETER UpdateServer
	WSUS server hostname. 
	Short or FQDN works.
.PARAMETER UpdateServerPort
	TCP Port number to connect to the WSUS Server through IIS.
.PARAMETER SkipOutGrid
	This switch will skip displaying the end results that uses Out-GridView.
.LINK
	http://wiki.bonusbits.com/main/PSScript:Get-PendingPatches
	http://wiki.bonusbits.com/main/PSModule:WindowsPatching
	http://wiki.bonusbits.com/main/HowTo:Use_WindowsPatching_PowerShell_Module_to_Automate_Patching_with_WSUS_as_the_Client_Patch_Source
	http://wiki.bonusbits.com/main/HowTo:Setup_PowerShell_Module
	http://wiki.bonusbits.com/main/HowTo:Enable_Remote_Signed_PowerShell_Scripts
#>

#endregion Help

#region Parameters

	[CmdletBinding()]
	Param (
		[parameter(Mandatory=$false,Position=0)][string]$ComputerName,
		[parameter(Mandatory=$false)][array]$List,
		[parameter(Mandatory=$false)][switch]$FileBrowser,
		[parameter(Mandatory=$false)][array]$WsusGroups,
		[parameter(Mandatory=$false)][string]$UpdateServer,
		[parameter(Mandatory=$false)][int]$UpdateServerPort,
		[parameter(Mandatory=$false)][int]$MaxJobs = '300', #Because the entire task is rather quick it's better to keep this low for overall speed.
		[parameter(Mandatory=$false)][int]$JobQueTimeout = '1800', #This timer starts after all jobs have been queued.
		[parameter(Mandatory=$false)][switch]$SkipOutGrid
	)

#endregion Parameters

	If (!$Global:WindowsPatchingDefaults) {
		#  #  . "$Global:WindowsPatchingModulePath\SubScripts\MultiShow-WPMErrors_1.0.0.ps1"
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

	# PATHS NEEDED AT TOP
	[string]$ModuleRootPath = $Global:WindowsPatchingModulePath
	[string]$SubScripts = Join-Path -Path $ModuleRootPath -ChildPath 'SubScripts'
	[string]$HostListPath = ($Global:WindowsPatchingDefaults.HostListPath)

#region Prompt: Missing Host Input

	#region Prompt: FileBrowser
	
		If ($FileBrowser.IsPresent -eq $true) {
			#  #  . "$Global:WindowsPatchingModulePath\SubScripts\Get-FileName_1.0.0.ps1"
			Clear
			Write-Host 'SELECT FILE CONTAINING A LIST OF HOSTS TO PATCH.'
			Get-FileName -InitialDirectory $HostListPath -Filter "Text files (*.txt)|*.txt|Comma Delimited files (*.csv)|*.csv|All files (*.*)|*.*"
			[string]$FileName = $Global:GetFileName.FileName
			[string]$HostListFullName = $Global:GetFileName.FullName
		}
	
	#endregion Prompt: FileBrowser

	#region Prompt: Host Input

		If (!($FileName) -and !($ComputerName) -and !($List) -and !($WsusGroups)) {
#			[boolean]$HostInputPrompt = $true
			Clear
			$promptitle = ''
			
			$message = "Please Select a Host Entry Method:`n"
			
			# HM = Host Method
			$hmc = New-Object System.Management.Automation.Host.ChoiceDescription "&ComputerName", `
			    'Enter a single hostname'

			$hml = New-Object System.Management.Automation.Host.ChoiceDescription "&List", `
			    'Enter a List of hostnames separated by a commna without spaces'
				
			$hmf = New-Object System.Management.Automation.Host.ChoiceDescription "&File", `
			    'Text file name that contains a List of ComputerNames'
				
			$hmg = New-Object System.Management.Automation.Host.ChoiceDescription "&WsusGroups", `
			    'Enter a List of WSUS Group names separated by commas without spaces'
			
			$exit = New-Object System.Management.Automation.Host.ChoiceDescription "E&xit", `
			    'Exit Script'

			$options = [System.Management.Automation.Host.ChoiceDescription[]]($hmc, $hml, $hmf, $exit)
			
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
				#  . "$Global:WindowsPatchingModulePath\SubScripts\Get-FileName_1.0.0.ps1"
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
				Clear
				Write-Host ''
				Write-Host 'ERROR: Host method entry issue'
				Write-Host ''
				Reset-WindowsPatchingUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables
				Break
			}
		}
		
	#endregion Prompt: Host Input

#endregion Prompt: Missing Host Input

#region Variables

	# DEBUG
	$ErrorActionPreference = "Inquire"
	
	# SET ERROR MAX LIMIT
	$MaximumErrorCount = '1000'
	$Error.Clear()

	# SCRIPT INFO
	[string]$ScriptVersion = '1.1.5'
	[string]$ScriptTitle = "Check for Pending Windows Patches by Levon Becker"
	[int]$DashCount = '49'

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
	[string]$LogPath = ($Global:WindowsPatchingDefaults.GetPendingPatchesLogPath)
	[string]$ScriptLogPath = Join-Path -Path $LogPath -ChildPath 'ScriptLogs'
	[string]$JobLogPath = Join-Path -Path $LogPath -ChildPath 'JobData'
	[string]$ResultsPath = ($Global:WindowsPatchingDefaults.GetPendingPatchesResultsPath)
	
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
					Write-Host ''
					Write-Host "ERROR: INPUT FILE NOT FOUND ($HostListFullName)" -ForegroundColor White -BackgroundColor Red
					Write-Host ''
#					If ((Test-Path -Path "$SubScripts\Reset-WindowsPatchingUI_1.0.4.ps1") -eq $true) {
#						  . "$SubScripts\Reset-WindowsPatchingUI_1.0.4.ps1"
						Reset-WindowsPatchingUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables
#					}
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
	[string]$ResultsTextFileName = "Get-PendingPatches_Results_" + $FileDateTime + $TimeZoneString + "_($InputDesc).log"
	[string]$ResultsCSVFileName = "Get-PendingPatches_Results_" + $FileDateTime + $TimeZoneString + "_($InputDesc).csv"
	[string]$JobLogFileName = "JobData_" + $FileDateTime + $TimeZoneString + "_($InputDesc).log"

	# PATH + FILENAMES
	[string]$ResultsTextFullName = Join-Path -Path $ResultsPath -ChildPath $ResultsTextFileName
	[string]$ResultsCSVFullName = Join-Path -Path $ResultsPath -ChildPath $ResultsCSVFileName
	[string]$JobLogFullName = Join-Path -Path $JobLogPath -ChildPath $JobLogFileName


#endregion Variables

#region Check Dependencies
	
	# Create Array of Paths to Dependancies to check
	CLEAR
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
	# Get PowerShell Version with External Script
	If ($SkipAllVmware.IsPresent -eq $true) {
		Set-WinTitleBase -ScriptVersion $ScriptVersion 
	}
	Else {
		Set-WinTitleBase -ScriptVersion $ScriptVersion -IncludePowerCLI
	}
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
		Set-WinTitleJobCount -WinTitleInput $Global:WinTitleInput -JobCount $Global:GetJobCount.JobsRunning
			
		# CREATE RESULTS TEMP DIRECTORY
		If ((Test-Path -Path $ResultsTempPath) -ne $true) {
			New-Item -Path $ResultsPath -Name $ResultsTempFolder -ItemType Directory -Force | Out-Null
		}
		
		# CREATE WIP TEMP DIRECTORY
		If ((Test-Path -Path $WIPTempPath) -ne $true) {
			New-Item -Path $WIPPath -Name $WIPTempFolder -ItemType Directory -Force | Out-Null
		}
		
		# CREATE RESULT TEMP FILE FOR FAILED SYSTEMS
		If ($Global:TestConnections.FailedCount -gt '0') {
			Get-Runtime -StartTime $ScriptStartTime
			[string]$FailedConnectResults = 'False,False,Error,False' + ',' + $Global:GetRuntime.Runtime + ',' + $ScriptStartTimeF + ' ' + $TimeZone + ',' + $Global:GetRuntime.EndTimeF + ' ' + $TimeZone + ',' + "Unknown,Unknown,Unknown,Unknown,Unknown,Failed Connection" + ',' + $ScriptVersion + ',' + $ScriptHost + ',' + $UserName
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
			[boolean]$FirstGroup = $false
			Foreach ($ComputerName in $HostList) {
				$TaskProgress = [int][Math]::Ceiling((($i / $HostCount) * 100))
				# Progress Bar
				Write-Progress -Activity "STARTING CHECK FOR PENDING UPDATES ON - ($ComputerName)" -PercentComplete $TaskProgress -Status "OVERALL PROGRESS - $TaskProgress%"
				
				# UPDATE COUNT AND WINTITLE
				Get-JobCount
				Set-WinTitleJobCount -WinTitleInput $Global:WinTitleInput -JobCount $Global:GetJobCount.JobsRunning
				# CLEANUP FINISHED JOBS
				Remove-Jobs -JobLogFullName $JobLogFullName

				#region Throttle Jobs
					
					# PAUSE FOR A FEW AFTER THE FIRST 25 ARE QUEUED
#					If (($Global:GetJobCount.JobsRunning -ge '20') -and ($FirstGroup -eq $false)) {
#						Sleep -Seconds 5
#						[boolean]$FirstGroup = $true
#					}
				
					While ($Global:GetJobCount.JobsRunning -ge $MaxJobs) {
						Sleep -Seconds 5
						Remove-Jobs -JobLogFullName $JobLogFullName
						Get-JobCount
						Set-WinTitleJobCount -WinTitleInput $Global:WinTitleInput -JobCount $Global:GetJobCount.JobsRunning
					}
				
				#endregion Throttle Jobs
				
				# Set Job Start Time Used for Elapsed Time Calculations at End ^Needed Still?
				[string]$JobStartTime1 = Get-Date -Format g
				
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
							$SubScripts = $args[8]
							$LogPath = $args[9]
							$ScriptVersion = $args[10]
							$ResultsTempPath = $args[11]
							$WIPTempPath = $args[12]
							$Timezone = $args[13]
							
							$testcount = 1
							
							# DATE AND TIME
							$JobStartTimeF = Get-Date -Format g
							$JobStartTime = Get-Date
							
							# NETWORK SHARES
							[string]$RemoteShareRoot = '\\' + $ComputerName + '\C$' 
							[string]$RemoteShare = Join-Path -Path $RemoteShareRoot -ChildPath 'WindowsScriptTemp'
							
							# HISTORY LOG
							[string]$HistoryLogFileName = $ComputerName + '_GetPendingPatches_History.log' 
							[string]$LocalHistoryLogPath = Join-Path -Path $LogPath -ChildPath 'History' 
							[string]$RemoteHistoryLogPath = $RemoteShare 
							[string]$LocalHistoryLogFullName = Join-Path -Path $LocalHistoryLogPath -ChildPath $HistoryLogFileName
							[string]$RemoteHistoryLogFullName = Join-Path -Path $RemoteHistoryLogPath -ChildPath $HistoryLogFileName
							
							# LATEST LOG
							[string]$LatestLogFileName = $ComputerName + '_GetPendingPatches_Latest.log' 
							[string]$LocalLatestLogPath = Join-Path -Path $LogPath -ChildPath 'Latest' 
							[string]$RemoteLatestLogPath = $RemoteShare 
							[string]$LocalLatestLogFullName = Join-Path -Path $LocalLatestLogPath -ChildPath $LatestLogFileName 
							[string]$RemoteLatestLogFullName = Join-Path -Path $RemoteLatestLogPath -ChildPath $LatestLogFileName
							
							# RESULTS TEMP
							[string]$ResultsTempFileName = $ComputerName + '_Results.log'
							[string]$ResultsTempFullName = Join-Path -Path $ResultsTempPath -ChildPath $ResultsTempFileName
							
							# SET INITIAL JOB SCOPE VARIBLES
							[boolean]$Failed = $false
							[boolean]$CompleteSuccess = $false
							[string]$OSArch = 'Unknown'
							[string]$HostIP = 'Unknown'
							[string]$HostDomain = 'Unknown'
							[Boolean]$ConnectSuccess = $true

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
							
								If ((test-path -Path $RemoteShare) -eq $False) {
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
							
							#region Temp: Rename Old Logs
							
								$OldHistoryFileFullName = '\\' + $ComputerName + '\c$\WindowsScriptTemp\' + $ComputerName + '_GetPendingUpdates.log'
								If ((Test-Path -Path $OldHistoryFileFullName) -eq $true) {
									Rename-Item -Path $OldHistoryFileFullName -NewName $HistoryLogFileName -Force
								}
								$OldHistoryFileFullName = '\\' + $ComputerName + '\c$\WindowsScriptTemp\' + $ComputerName + '_GetPendingUpdates_History.log'
								If ((Test-Path -Path $OldHistoryFileFullName) -eq $true) {
									Rename-Item -Path $OldHistoryFileFullName -NewName $HistoryLogFileName -Force
								}
								$OldLatestFileFullName = '\\' + $ComputerName + '\c$\WindowsScriptTemp\' + $ComputerName + '_GetPendingUpdates_Latest.log'
								If ((Test-Path -Path $OldLatestFileFullName) -eq $true) {
									Rename-Item -Path $OldLatestFileFullName -NewName $LatestLogFileName -Force
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
									"JOB STARTED: $DateTimeF $TimeZone",
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
										[string]$ScriptErrors += "Less Than Minimum Drive Space#  . "
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
										[string]$ScriptErrors += "Not Enough Disk Space for Logs#  . "
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
								$results = $null
								[array]$results = ($Global:GetOSVersion | Format-List | Out-String).Trim('')
								$ScriptLogData += @(
									'',
									'GET OS VERSION',
									'---------------',
									"$results"
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
								$results = $null
								[array]$results = ($Global:gethostdomain | Format-List | Out-String).Trim('')
								$ScriptLogData += @(
									'',
									'GET HOST DOMAIN',
									'----------------',
									"$results"
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
								$results = $null
								[array]$results = ($Global:GetHostIP | Format-List | Out-String).Trim('')
								$ScriptLogData += @(
									'',
									'GET HOST IP',
									'------------',
									"$results"
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
						
								#region Get Pending Updates
									
									Get-PendingUpdates -ComputerName $ComputerName 
									If ($Global:GetPendingUpdates.Success -eq $true) {
										[boolean]$GetPendingUpdatesSuccess = $Global:GetPendingUpdates.Success
										$PendingPatchCount = $Global:GetPendingUpdates.PatchCount
										[string]$COMError = 'None'
										If ($PendingPatchCount -gt 0) {
											$PendingList = $null
											# Create Array Report Objects
											[array]$PendingList = $Global:GetPendingUpdates.Report
											$KB = $null
											Foreach ($PendingPatch in $PendingList) {
												[string]$KB = ($PendingPatch.KB | Out-String).Trim('')
												[string]$KBList += $KB + ' '
											}
										}
										Else {
											$PendingList = 'NO PENDING PATCHES'
											$KBList = 'None'
										}
									}
									Else {
										[boolean]$Failed = $true
										[boolean]$GetPendingUpdatesSuccess = $false
										$PendingPatchCount = 'Error'
										$KBList = 'Error'
										[string]$COMError = ($Global:GetPendingUpdates.Error | Out-String).Trim('')
										If ((Select-String -InputObject $COMError -Pattern '800706ba' -Quiet) -eq $true) {
											[string]$ScriptErrors += 'Firewall Blocking Dynamic RPC for COM Object '
										}
										ElseIf ((Select-String -InputObject $COMError -Pattern '80070005' -Quiet) -eq $true) {
											[string]$ScriptErrors += 'Logon Failure for NT AUTHORITY\SYSTEM on Remote System EventID:529 '
										}
										ElseIf ((Select-String -InputObject $COMError -Pattern '8007000e' -Quiet) -eq $true) {
											[string]$ScriptErrors += 'Remote System Out of Resources or Disjoined from Domain '
										}
										Else {
											[string]$ScriptErrors += $COMError
										}
									}
									# ADD RESULTS TO SCRIPT LOG ARRAY
									$results = $null
									[array]$results = ($Global:GetPendingUpdates | Format-List | Out-String).Trim('')
									$results2 = $null
									[string]$results2 = ($Global:GetPendingUpdates.Report | Format-List | Out-String).Trim('')
									$ScriptLogData += @(
										'',
										'GET WINDOWS UPDATE INFO',
										'-----------------------',
										"$results",
										'',
										'PENDING PATCHES',
										'---------------',
										"$results2"
									)

								#endregion Get Pending Updates
							
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
							
								If (!$ScriptErrors) {
									[string]$ScriptErrors = 'None'
								}
							
							#endregion Set Results if Missing
							
							#region Output Results to File
							
								Get-Runtime -StartTime $JobStartTime #Results used for History Log Footer too
								[string]$TaskResults = $ComputerName + ',' + $CompleteSuccess + ',' + $GetPendingUpdatesSuccess + ',' + $PendingPatchCount + ',' + $ConnectSuccess + ',' + $Global:GetRuntime.Runtime + ',' + $JobStartTimeF + ' ' + $TimeZone + ',' + $Global:GetRuntime.EndTimeF + ' ' + $TimeZone + ',' + $OSVersion + ',' + $OSArch + ',' + $HostIP + ',' + $HostDomain + ',' + $KBList + ',' + $ScriptErrors + ',' + $ScriptVersion + ',' + $ScriptHost + ',' + $UserName
								
								[int]$loopcount = 0
								[boolean]$errorfree = $false
								DO {
									$loopcount++
									Try {
										Out-File -FilePath $ResultsTempFullName -Encoding ASCII -InputObject $TaskResults -ErrorAction Stop
										[boolean]$errorfree = $true
									}
									# IF FILE BEING ACCESSED BY ANOTHER SCRIPT CATCH THE TERMINATING ERROR
									Catch [System.IO.IOException] {
										[boolean]$errorfree = $false
										Sleep -Milliseconds 500
										# Could write to ScriptLog which error is caught
									}
									# ANY OTHER EXCEPTION
									Catch {
										[boolean]$errorfree = $false
										Sleep -Milliseconds 500
										# Could write to ScriptLog which error is caught
									}
								}
								# Try until writes to output file or 
								Until (($errorfree -eq $true) -or ($loopcount -ge '150'))
							
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
									"JOB:             [ENDED] $DateTimeF $TimeZone",
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


					} -ArgumentList $ComputerName,$Assets,$SubScripts,$JobLogFullName,$ResultsTextFullName,$ScriptHost,$UserDomain,$UserName,$SubScripts,$LogPath,$ScriptVersion,$ResultsTempPath,$WIPTempPath,$Timezone | Out-Null

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
		Set-WinTitleJobCount -WinTitleInput $Global:WinTitleInput -JobCount $Global:GetJobCount.JobsRunning
		
		# Job Monitoring Function Will Loop Until Timeout or All are Completed
		Watch-Jobs -JobLogFullName $JobLogFullName -Timeout $JobQueTimeout -Activity "CHECKING FOR PENDING UPDATES" -WinTitleInput $Global:WinTitleInput
		
	#endregion Job Monitor

#endregion Tasks

#region Cleanup WIP

	# GATHER LIST AND CREATE RESULTS FOR COMPUTERNAMES LEFT IN WIP
	If ((Test-Path -Path "$WIPTempPath\*") -eq $true) {
		Get-Runtime -StartTime $ScriptStartTime
		[string]$TimedOutResults = 'False,False,Error,False' + ',' + $Global:GetRuntime.Runtime + ',' + $ScriptStartTimeF + ' ' + $TimeZone + ',' + $Global:GetRuntime.EndTimeF + ' ' + $TimeZone + ',' + "Unknown,Unknown,Unknown,Unknown,Unknown,Timed Out" + ',' + $ScriptVersion + ',' + $ScriptHost + ',' + $UserName

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
		"Check Success",
		"Pending",
		"Connected",
		"Runtime",
		"Starttime",
		"Endtime",
		"Operating System",
		"OSArch",
		"Host IP",
		"Host Domain",
		"Pending Patches",
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
		$OutFile | Out-GridView -Title "Get Pending Patches Results for $InputItem"
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
	Get-DiskSpace
	Get-Runtime
	Get-JobCount
	Get-HostDomain
	Get-HostIP
	Get-OSVersion
	Get-PendingPatches
	Get-TimeZone
	Watch-Jobs
	Remove-Jobs
	Reset-WindowsPatchingUI
	Show-ScriptHeader
	Test-Connections
	Test-Permissions
	MultiSet-WinTitle
	MultiStop-Watch
	MultiShow-Script-Status
#>

<# TO DO
#>

<# Change Log
1.0.0 - 05/14/2012
	Created.
1.0.1 - 05/15/2012
	Fixed object outputs for results to not have spaces or CR
	Added Hosts that failed connection test to Results.
1.0.2 - 05/15/2012
	Added ScriptErrors logic and output
	Removed ScriptLog throughout
1.0.3 - 05/16/2012
	Switched to Get-OSVersion 1.0.9
	Removed FailedAccess logic now that it's in the results.
	Switched to Test-Connections 1.0.6
	Switched to Test-Connections 1.0.7
1.0.4 - 08/24/2012
	Changed Remote Client Working Directory to WindowsScriptTemp
1.0.5 - 10/22/2012
	Switched to Reset-WindowsPatchingUI 1.0.3
1.0.6 - 11/27/2012
	Removed FileName Parameter
	Changed WindowsScriptsTemp to WindowsScriptTemp
1.0.7 - 12/04/2012
	Switched to Test-Connection 1.0.8
	Changed logic for if all systems fail connection test it will reset the UI
1.0.8 - 12/17/2012
	Added Get-DiskSpace subscript call and check for writing logs.
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
	Switched to Test-Connections 1.0.9
	Tons of code cleanup and region additions
1.0.9 - 12/18/2012
	Added Reset UI before breaks/returns
	Reworked the Dependency check section.
1.1.0 - 12/26/2012
	Switched to Remove-Jobs 1.0.6
	Switched to Watch-Jobs 1.0.5
	Cleanup up code a little
	Change Get Hard Drive Space section and split check to two variables.
1.1.1 - 12/28/2012
	Removed Dot sourcing subscripts and load all when module is imported.
	Changed Show-ScriptStatus functions to not have second hypen in name.
	Changed Set-WinTitle functions to not have second hypen in name.
1.1.1 - 01/04/2013
	Removed -SubScript parameter from all subfunction calls.
	Removed dot sourcing subscripts because all are loaded when the module is imported now.
	Removed dependency check for subscripts.
	Added Import WindowsPatching Module to Background jobs.
	Removed Runas 32-bit from background jobs.
	Added Timezone argument passthrough to background jobs for logs.
1.1.2 - 01/09/2013
	Added Timezone to start and end times in results.
1.1.3 - 01/14/2013
	Renamed WPM to WindowsPatching
1.1.4 - 01/18/2013
	Added WsusGroups, UpdateServer and WsusPort Parameters plus logic to handle it.
		This can eliminate the need of making text file lists and just patch a specific 
		WSUS group or groups.
	Renamed HostInputDesc to InputDesc
1.1.5 - 01/22/2013
	Renamed PendingUpdates to PendingPatches
#>


#endregion Notes
