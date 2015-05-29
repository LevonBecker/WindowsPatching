#requires –version 2.0

Function Install-Patches {

#region Help

<#
.SYNOPSIS
	Install approved Windows patches from a WSUS server.
.DESCRIPTION
	This Powershell script can be used to install Windows patches distributed
	from a WSUS server.
	
	BASIC SCRIPT FLOW:
	--------------------------------------------------------------------
	1)	Test Connection
	2)	Check Disk Space
	3)	Check for Pending Reboot (Reboot if Pending)
	4)	Download, Install and Reboot for Windows Patches until none left
	5)	Results Report and Write Logs
.NOTES
	VERSION:    2.8.2
	AUTHOR:     Levon Becker
	EMAIL:      PowerShell.Guru@BonusBits.com 
	ENV:        Powershell v2.0+, CLR 4.0+
	TOOLS:      PowerGUI Script Editor
	
	REQUIREMENTS
	===================================================================
	
	System Running the Script
	-------------------------
	1) Powershell v2.0+
	2) .Net 4.0+
	3) PowerShell running CLR 4.0+
		a) http://wiki.bonusbits.com/main/HowTo:Enable_.NET_4_Runtime_for_PowerShell_and_Other_Applications
	4) Execution Policy Unrestricted or RemoteSigned
	5) Remote registry, WIMRM and RPC services running
	2) Firewall access to remote computer
	3) Local Admin Permissions on remote computer
	4) Short name resolution for remote computer
	5) Use the actual hostname and not a DNS alias or IP
	
	Remote Computer to be Patched
	------------------------------
	1) Setup to pull patches from WSUS server
	2) Client in a WSUS ComputerName Group with approved patches
	3) Currently Powershell is required on the remote computer
	4} Remote registry, WIMRM and RPC services running
	5) Firewall set to allow all TCP from scipt host IP (easiest)
	
	TESTED OPERATING SYSTEMS
	------------------------
	Windows Server 
		2000
		2003
		2008
		2008 R2
	Windows Workstation
		XP
		Vista
		7
.INPUTS
	ComputerName    Single Hostname
	List            List of Hostnames
	FileBrowser     File with List of Hostnames
	
	DEFAULT FILEBROWSER PATH
	------------------------
	HOSTLISTS
	%USERPROFILE%\Documents\HostList
.OUTPUTS
	DEFAULT PATHS
	-------------
	RESULTS
	%USERPROFILE%\Documents\Results\Install-Patches
	
	LOGS
	%USERPROFILE%\Documents\Logs\Install-Patches
	+---History
	+---JobData
	+---Latest
	+---Temp
	+---WIP
.EXAMPLE
	Install-Patches -ComputerName server01 
	Patch a single computer.
.EXAMPLE
	Install-Patches server01 
	Patch a single computer.
	The ComputerName parameter is in position 0 so it can be left off for a
	single computer.
.EXAMPLE
	Install-Patches server01 -NoReboot
	Patch a single computer.
	The ComputerName parameter is in position 0 so it can be left off for a
	single computer.
	NoReboot:
		If not pending a reboot from a prior activity, then install as 
		many rounds of patches needed until it needs a reboot.
.EXAMPLE
	Install-Patches -List server01,server02
	Patch a list of hostnames comma separated without spaces.
.EXAMPLE
	Install-Patches -List $MyHostList 
	Patch a list of hostnames from an already created array variable.
	i.e. $MyHostList = @("server01","server02","server03")
.EXAMPLE
	Install-Patches -FileBrowser 
	This switch will launch a separate file browser window.
	In the window you can browse and select a text or csv file from anywhere
	accessible by the local computer that has a list of host names.
	The host names need to be listed one per line or comma separated.
	This list of system names will be used to perform the script tasks for 
	each host in the list.
.EXAMPLE
	Install-Patches -FileBrowser -SkipOutGrid
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
	Install-Patches -WsusGroups group01 
	This will query the WSUS Server for a list of hostnames in a single or
	multiple WSUS groups to run the script against.
	This is an array so more than one can be listed as a comma seperated list
	without spaces.
.EXAMPLE
	Install-Patches -WsusGroups group01,group02,group03 
	This will query the WSUS Server for a list of hostnames in a single or
	multiple WSUS groups to run the script against.
	This is an array so more than one can be listed as a comma seperated list
	without spaces.
.EXAMPLE
	Install-Patches -WsusGroups group01,group02,group03 -NoReboot
	WsusGroups:
		This will query the WSUS Server for a list of hostnames in a single or
		multiple WSUS groups to run the script against.
		This is an array so more than one can be listed as a comma seperated list
		without spaces.
	Noreboot:
		This will skip all reboots and if it no Pending reboot at the start
		it will install the first round of patches.
		It will indicate in the results if the system is pending a reboot.
.EXAMPLE
	Install-Patches -WsusGroups group01,group02,group03 -ExcludeComputers server01,server02,server03
	WsusGroups:
		This will query the WSUS Server for a list of hostnames in a single or
		multiple WSUS groups to run the script against.
		This is an array so more than one can be listed as a comma seperated list
		without spaces.
	ExcludeComputers:
		A PowerShell array list of hostnames to exclude.
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
.PARAMETER ExcludeComputers
	A PowerShell array List of hostnames to exclude.
.PARAMETER MaxJobs
	Maximum amount of background jobs to run simultaneously. 
	Adjust depending on how much memory and load the localhost can handle.
	It's not recommended to set higher than 500.
	Default = 400
.PARAMETER JobQueTimeout
	Maximum amount of time in seconds to wait for the background jobs to finish 
	before timing out. 	Adjust this depending out the speed of your environment 
	and based on the maximum jobs ran simultaneously.
	
	If the MaxJobs setting is turned down, but there are a lot of servers this 
	may need to be increased.
	
	This timer starts after all jobs have been queued.
	Default = 10800 (3 hours)
.PARAMETER MinFreeMB
	This is the value used when checking C: hard drive space.  
	The default	is 500MB. 
	Enter a number in Megabytes.
.PARAMETER UseAltPCCreds
	This switch will trigger a be prompt to enter alternate credentials for 
	connecting to all the computers. (WIP)
.PARAMETER SkipOutGrid
	This switch will skip displaying the end results that uses Out-GridView.
.PARAMETER UpdateServer
	WSUS server hostname. 
	Short or FQDN works.
.PARAMETER UpdateServerPort
	TCP Port number to connect to the WSUS Server through IIS.
.PARAMETER SkipDiskSpaceCheck
	If this switch is present the task to verify if there is enough Disk Space 
	on each remote computer will be skipped.
.PARAMETER NoReboot
	This switch will skip rebooting the remote client for any reason.
	However if there are no pending reboots found at the start, it
	will attempt to install the first round of patches needed.
	This can be useful to patch up a group of servers during production
	hours and reboot them later by running the cmdlet against them again
	or by other manual or script methods.
.PARAMETER SkipRebootWarning
	If this switch is present the reboot acknowledgement prompt will be skipped.
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
			[parameter(Mandatory=$false)][array]$ExcludeComputers,
			[parameter(Mandatory=$false)][int]$MaxJobs = '400', #Adjust depending on how much load the localhost can handle
			[parameter(Mandatory=$false)][int]$JobQueTimeout = '10800', #This timer starts after all jobs have been queued.
			[parameter(Mandatory=$false)][int]$MinFreeMB = '500',
			[parameter(Mandatory=$false)][string]$UpdateServer,
			[parameter(Mandatory=$false)][int]$UpdateServerPort,
			[parameter(Mandatory=$false)][switch]$SkipDiskSpaceCheck,
			[parameter(Mandatory=$false)][switch]$SkipOutGrid,
			[parameter(Mandatory=$false)][switch]$UseAltPCCreds,
			[parameter(Mandatory=$false)][switch]$NoReboot,
			[parameter(Mandatory=$false)][switch]$SkipRebootWarning
	       )
	   
#endregion Parameters

	If (!$Global:WindowsPatchingDefaults) {
		Show-WindowsPatchingErrorMissingDefaults
	}

	# GET STARTING GLOBAL VARIABLE LIST
	New-Variable -Name StartupVariables -Force -Value (Get-Variable -Scope Global | Select -ExpandProperty Name)
	
	# CAPTURE CURRENT TITLE
	[string]$StartingWindowTitle = $Host.UI.RawUI.WindowTitle
	[string]$HostListPath = ($Global:WindowsPatchingDefaults.HostListPath)
	
	# PATHS NEEDED AT TOP
	[string]$ModuleRootPath = $Global:WindowsPatchingModulePath
	[string]$SubScripts = Join-Path -Path $ModuleRootPath -ChildPath 'SubScripts'
	
	# SET MISSING PARAMETERS
	If (!$UpdateServer) {
		[string]$UpdateServer = ($Global:WindowsPatchingDefaults.UpdateServer)
	}
	
	If (!$UpdateServerPort) {
		[int]$UpdateServerPort = ($Global:WindowsPatchingDefaults.UpdateServerPort)
	}
	
#region Prompt: Missing Input

	#region Prompt: FileBrowser
	
		If ($FileBrowser.IsPresent -eq $true) {
			Clear
			Write-Host 'SELECT FILE CONTAINING A LIST OF HOSTS TO PATCH.'
			Get-FileName -InitialDirectory $HostListPath -Filter "Text files (*.txt)|*.txt|Comma Delimited files (*.csv)|*.csv|All files (*.*)|*.*"
			[string]$FileName = $Global:GetFileName.FileName
			[string]$HostListFullName = $Global:GetFileName.FullName
		}
	
	#endregion Prompt: FileBrowser
	
	#region Prompt: Host Input

		If (!($FileName) -and !($ComputerName) -and !($List) -and !($WsusGroups)) {
			# Set to to trigger other prompts, guessing user doesn't want to type out parameters.
			[boolean]$HostInputPrompt = $true
			Clear
			$promptitle = ''
			
			$Message = "SELECT HOST INPUT METHOD:"
			
			# HM = Host Method
			$HMC = New-Object System.Management.Automation.Host.ChoiceDescription "&ComputerName", `
			    'Enter a single hostname'

			$HML = New-Object System.Management.Automation.Host.ChoiceDescription "&List", `
			    'Enter a List of hostnames separated by a commna without spaces'
				
			$HMF = New-Object System.Management.Automation.Host.ChoiceDescription "&File", `
			    'Text or CSV file that contains a List of ComputerNames'
			
			$HMG = New-Object System.Management.Automation.Host.ChoiceDescription "&WsusGroups", `
			    'Enter a List of WSUS Group names separated by commas without spaces'
			
			$Exit = New-Object System.Management.Automation.Host.ChoiceDescription "E&xit", `
			    'Exit Script'

			$Options = [System.Management.Automation.Host.ChoiceDescription[]]($HMC, $HML, $HMF, $HMG, $Exit)
			
			$Choice = $host.ui.PromptForChoice($promptitle, $Message, $Options, 4) 
			
			# RESET WINDOW TITLE AND BREAK IF EXIT SELECTED
			If ($Choice -eq 4) {
				Reset-WindowsPatchingUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables -SkipPrompt
				Break
			}
			Else {
			Switch ($Choice)
				{
				    0 {$HostInputMethod = 'ComputerName'} 
					1 {$HostInputMethod = 'List'}
					2 {$HostInputMethod = 'File'}
					3 {$HostInputMethod = 'WsusGroup'}
				}
			}
			
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
				Do {
					Clear
					Write-Host ''
	#				Write-Host 'Enter a List of hostnames separated by a comma without spaces to patch.'
					$CommaList = $(Read-Host -Prompt 'Enter List')
					# Read-Host only returns String values, so need to split up the hostnames and put into array
					[array]$List = $CommaList.Split(',')
					}
				Until ($List)
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
				$CommaList = $(Read-Host -Prompt 'Enter WSUS Groups')
				# Read-Host only returns String values, so need to split up the hostnames and put into array
				[array]$WsusGroups = $CommaList.Split(',')
			}
			Else {
				Clear
				Write-Host ''
				Write-Host 'ERROR: Host method entry issue' -ForegroundColor White -BackgroundColor Red
				Reset-WindowsPatchingUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables
				Break
			}
		}
		
		#endregion Prompt: Host Input
		
	#region Prompt: Alternate PC Credentials

			If ($HostInputPrompt -eq $true) {
				Clear
				$Title = ''
				$Message = 'ENTER ALTERNATE PC CREDENTIALS?'
			
				$Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
				    'Enter UserName and password for vCenter access instead of using current credintials.'
			
				$No = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
				    'Do not enter UserName and password for vCenter access. Just use current.'
			
				$Options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No)
			
				$Choice = $host.ui.PromptForChoice($Title, $Message, $Options, 1) 
			
				switch ($Choice)
				{
				    0 {[switch]$UseAltPCCreds = $true} 
				    1 {[switch]$UseAltPCCreds = $false} 
				}
				If ($UseAltPCCreds.IsPresent -eq $true) {
					Do {
						Try {
							$PCCreds = Get-Credential -ErrorAction Stop
							[boolean]$UseAltPCCredsBool = $true
							[boolean]$getcredssuccess = $true
						}
						Catch {
							[boolean]$getcredssuccess = $false
						}
					}
					Until ($getcredssuccess -eq $true)
				}
				ElseIf ($UseAltPCCreds.IsPresent -eq $false) {
					[boolean]$UseAltPCCredsBool = $false
				}
			}

	#endregion Prompt: Alternate PC Credentials
		
	#region Prompt: Hard Disk Space Check
		
			If ($HostInputPrompt -eq $true) {
				Clear
				$Title = ''
				$Message = 'CHECK C: DRIVE FOR MINIMUM SPACE?'

				$Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
				    'Check that there is a minimum of $MinFreeMB MB free space on C:'

				$No = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
				    'Do not check for minimum disk space on C:'
				
				$Exit = New-Object System.Management.Automation.Host.ChoiceDescription "E&xit", `
				    'Exit Script'

				$Options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No, $Exit)

				$Choice = $host.ui.PromptForChoice($Title, $Message, $Options, 0) 

				# RESET WINDOW TITLE AND BREAK IF EXIT SELECTED
				If ($Choice -eq 2) {
					Reset-WindowsPatchingUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables -SkipPrompt
					Break
				}

				switch ($Choice)
				{
				    0 {[switch]$SkipDiskSpaceCheck = $false} 
				    1 {[switch]$SkipDiskSpaceCheck = $true} 
				}
			}

		#endregion Prompt: Hard Disk Space Check
		
#endregion Prompt: Missing Input

#region Variables

	# DEBUG
	$ErrorActionPreference = "Inquire"
	
	# SET ERROR MAX LIMIT
	$MaximumErrorCount = '1000'

	# SCRIPT INFO
	[string]$ScriptVersion = '2.8.2'
	[string]$ScriptTitle = "Install Windows Patches by Levon Becker"
	[int]$DashCount = '40'

	# CLEAR VARIABLES
	$Error.Clear()
	# (NOT IN TEMPLATE)
	[int]$Global:connectfailed = 0
	[int]$Global:vmfailed = 0
	[int]$TotalHosts = 0

	# LOCALHOST
	[string]$ScriptHost = $Env:ComputerNAME
	[string]$UserDomain = $Env:UserDomain
	[string]$UserName = $Env:UserName
	[string]$FileDateTime = Get-Date -UFormat "%Y-%m%-%d_%H.%M"
	[datetime]$ScriptStartTime = Get-Date
	$ScriptStartTimeF = Get-Date -Format g
		
	# DIRECTORY PATHS
	[string]$LogPath = ($Global:WindowsPatchingDefaults.InstallPatchesLogPath)
	[string]$ScriptLogPath = Join-Path -Path $LogPath -ChildPath 'ScriptLogs'
	[string]$JobLogPath = Join-Path -Path $LogPath -ChildPath 'JobData'
	[string]$ResultsPath = ($Global:WindowsPatchingDefaults.InstallPatchesResultsPath)
	
	[string]$Assets = Join-Path -Path $ModuleRootPath -ChildPath 'Assets'
	
	# CONVERT SWITCH TO BOOLEAN TO PASS AS ARGUMENT
	[boolean]$SkipDiskSpaceCheckBool = ($SkipDiskSpaceCheck.IsPresent)
	[boolean]$UseAltPCCredsBool = ($UseAltPCCreds.IsPresent)
	[boolean]$NoRebootBool = ($NoReboot.IsPresent)
	
	#region  Set Logfile Name + Create HostList Array
	
		If ($ComputerName) {
			[string]$InputDesc = $ComputerName.ToUpper()
			# Inputitem used for WinTitle and Out-GridView Title at end
			[string]$InputItem = $ComputerName.ToUpper() #needed so the WinTitle will be uppercase
			[array]$HostList = $ComputerName.ToUpper()
		}
		ElseIf ($List) {
			[array]$List = $List | ForEach-Object {$_.ToUpper()}
			[string]$InputDesc = "List - " + ($List | Select -First 2) + " ..."
			# Inputitem used for WinTitle and Out-GridView Title at end
			[string]$InputItem = "List: " + ($List | Select -First 2) + " ..."
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
					Reset-WindowsPatchingUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables
					Return
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
		[array]$HostList = $HostList | Select -Unique
		
		#region Remove Excluded Computers
		
			If ($ExcludeComputers.Count -gt 0) {
				Foreach ($ClientName in $ExcludeComputers) {
					[array]$HostList = $HostList | Where-Object {$_ -ne $ClientName}
				}
				If ($HostList -eq $null) {
					Show-ScriptHeader -BlankLines '1' -DashCount $DashCount -ScriptTitle $ScriptTitle
					Write-Host ''
					Write-Host "ERROR: No Computers in List After Removing Excluded Computers" -BackgroundColor Red -ForegroundColor White
					Write-Host ''
					Reset-WindowsPatchingUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables
					Return
				}
			}
		
		#endregion Remove Excluded Computers
		
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
	[string]$ResultsTextFileName = "Install-Patches_Results_" + $FileDateTime + $TimeZoneString + "_($InputDesc).log"
	[string]$ResultsCSVFileName = "Install-Patches_Results_" + $FileDateTime + $TimeZoneString + "_($InputDesc).csv"
	[string]$JobLogFileName = "JobData_" + $FileDateTime + $TimeZoneString + "_($InputDesc).log"

	# PATH + FILENAMES
	[string]$ResultsTextFullName = Join-Path -Path $ResultsPath -ChildPath $ResultsTextFileName
	[string]$ResultsCSVFullName = Join-Path -Path $ResultsPath -ChildPath $ResultsCSVFileName
	[string]$JobLogFullName = Join-Path -Path $JobLogPath -ChildPath $JobLogFileName


#endregion Variables

#region Check Dependencies
	
	# Create Array of Paths to Dependencies to check
	CLEAR
	$DependencyList = @(
		"$LogPath",
		"$LogPath\History",
		"$LogPath\JobData",
		"$LogPath\Latest",
		"$LogPath\Temp",
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

#region Set Window Title
	
	Set-WinTitleStart -Title $ScriptTitle
	Show-ScriptHeader -BlankLines '1' -DashCount $DashCount -ScriptTitle $ScriptTitle
	Add-StopWatch
	Start-Stopwatch

#endregion Set Window Title

#region Prompt: About to Patch with Reboots

	If (($NoReboot.IsPresent -eq $false) -and ($SkipRebootWarning.IsPresent -eq $false)) {
		Show-ScriptHeader -BlankLines '1' -DashCount $DashCount -ScriptTitle $ScriptTitle
		Set-WinTitleBase -ScriptVersion $ScriptVersion 
		$Title = ''
		$Message = "You are about to install patches and allow reboots if necessary on ($InputDesc). `nDo you want to Continue?"

		$Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
		    'Continue with installing patches and reboot as needed'

		$No = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
		    'Do not continue'

		$Options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No)

		$Choice = $host.ui.PromptForChoice($Title, $Message, $Options, 1) 

		# RESET WINDOW TITLE AND BREAK IF EXIT SELECTED
		If ($Choice -eq 1) {
			Reset-WindowsPatchingUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables -SkipPrompt
			Return
		}
	}

#endregion Prompt: About to Patch with Reboots

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
		
		Test-Connections -List $HostList -MaxJobs '25' -TestTimeout '120' -JobmonTimeout '600' -ResultsTextFullName $ResultsTextFullName -JobLogFullName $JobLogFullName -TotalHosts $TotalHosts -DashCount $DashCount -ScriptTitle $ScriptTitle -UseAltPCCredsBool $UseAltPCCredsBool -PCCreds $PCCreds -WinTitleInput $Global:WinTitleInput
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
		[int]$TotalHosts = $Global:TestConnections.PassedCount
		Show-ScriptHeader -BlankLines '1' -DashCount $DashCount -ScriptTitle $ScriptTitle

	#endregion Test Connections
	
	#region Job Tasks
	
		Show-ScriptHeader -BlankLines '1' -DashCount $DashCount -ScriptTitle $ScriptTitle
		
		# STOP AND REMOVE ANY RUNNING JOBS
		Stop-Job *
		Remove-Job * -Force
		
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
		
		# CREATE RESULT TEMP FILE FOR FAILED SYSTEMS
		If ($Global:TestConnections.FailedCount -gt '0') {
			Get-Runtime -StartTime $ScriptStartTime
			[string]$FailedConnectResults = 'False,False,Unknown,0,0,0,Unknown,False' + ',' + $Global:GetRuntime.Runtime + ',' + $ScriptStartTimeF + ' ' + $TimeZone + ',' + $Global:GetRuntime.EndTimeF + ' ' + $TimeZone + ',' + "Unknown,Unknown,Unknown,Unknown,Unknown,Unknown,N/A,N/A,Failed Connection" + ',' + $ScriptVersion + ',' + $ScriptHost + ',' + $UserName
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
				Write-Progress -Activity "STARTING PATCHING ON - ($ComputerName)" -PercentComplete $TaskProgress -Status "OVERALL PROGRESS - $TaskProgress%"

				## THROTTLE RUNNING JOBS ##
				# Loop Until Less Than Max Jobs Running
				Get-JobCount
				Set-WinTitleJobCount -WinTitleInput $Global:WinTitleInput -JobCount $Global:getjobcount.JobsRunning
				Remove-Jobs -JobLogFullName $JobLogFullName
				
				#region Throttle Jobs
				
					# PAUSE FOR A FEW AFTER THE FIRST 25 ARE QUEUED
#					If (($Global:getjobcount.JobsRunning -ge '20') -and ($FirstGroup -eq $false)) {
#						Sleep -Seconds 5
#						[boolean]$FirstGroup = $true
#					}
				
					While ($Global:getjobcount.JobCount -ge $MaxJobs) {
						Sleep -Seconds 5
						Remove-Jobs -JobLogFullName $JobLogFullName
						Get-JobCount
						Set-WinTitleJobCount -WinTitleInput $Global:WinTitleInput -JobCount $Global:getjobcount.JobsRunning
					}
				
				#endregion Throttle Jobs
				
				#region Background Job
				
					Start-Job -ScriptBlock {

						#region Job Variables
						
							$ComputerName = $Args[0]
							$SubScripts = $args[1]
							$Assets = $args[2]
							$ScriptVersion = $Args[3]
							$JobLogFullName = $args[4]
							$MinFreeMB = $args[5]
							$SkipDiskSpaceCheckBool = $args[6]
							$UserDomain = $args[7]
							$UserName = $args[8]
							$ScriptHost = $args[9]
							$FileDateTime = $args[10]
							$LogPath = $args[11]
							$ResultsTextFullName = $args[12]
							$ResultsTempPath = $args[13]
							$WIPTempPath = $args[14]
							$NoRebootBool = $args[15]
							$Timezone = $args[16]
							
							# DATE AND TIME
							$day = Get-Date -uformat "%m-%d-%Y"
							$JobStartTime = Get-Date -Format g
							$JobStartTimeF = Get-Date -Format g
							
							# NETWORK SHARES
							[string]$RemoteShareRoot = '\\' + $ComputerName + '\C$' 
							[string]$RemoteShare = Join-Path -Path $RemoteShareRoot -ChildPath 'WindowsScriptTemp'
							
							# HISTORY LOG
							[string]$HistoryLogFileName = $ComputerName + '_InstallPatches_History.log' 
							[string]$LocalHistoryLogPath = Join-Path -Path $LogPath -ChildPath 'History' 
							[string]$RemoteHistoryLogPath = $RemoteShare 
							[string]$LocalHistoryLogFullName = Join-Path -Path $LocalHistoryLogPath -ChildPath $HistoryLogFileName
							[string]$RemoteHistoryLogFullName = Join-Path -Path $RemoteHistoryLogPath -ChildPath $HistoryLogFileName
							
							# LASTEST LOG
							[string]$LatestLogFileName = $ComputerName + '_InstallPatches_Latest.log' 
							[string]$LocalLatestLogPath = Join-Path -Path $LogPath -ChildPath 'Latest' 
							[string]$RemoteLatestLogPath = $RemoteShare 
							[string]$LocalLatestLogFullName = Join-Path -Path $LocalLatestLogPath -ChildPath $LatestLogFileName 
							[string]$RemoteLatestLogFullName = Join-Path -Path $RemoteLatestLogPath -ChildPath $LatestLogFileName
							
							# LAST PATCHES LOG
							[string]$LastPatchesLogFileName = $ComputerName + '_InstallPatches_Temp.log' 
							[string]$LocalLastPatchesLogPath = Join-Path -Path $LogPath -ChildPath 'Temp' 
							[string]$RemoteLastPatchesLogPath = $RemoteShare 
							[string]$LocalLastPatchesLogFullName = Join-Path -Path $LocalLastPatchesLogPath -ChildPath $LastPatchesLogFileName 
							[string]$RemoteLastPatchesLogFullName = Join-Path -Path $RemoteLastPatchesLogPath -ChildPath $LastPatchesLogFileName
							
							# RESULTS TEMP
							[string]$ResultsTempFileName = $ComputerName + '_Results.log'
							[string]$ResultsTempFullName = Join-Path -Path $ResultsTempPath -ChildPath $ResultsTempFileName
							
							# SCRIPTS
							[string]$UpdateVBFileName = 'Install-Patches_1.0.5.vbs'
							[string]$RemoteUpdateVB = Join-Path -Path $RemoteShare -ChildPath $UpdateVBFileName
							[string]$LocalUpdateVB = Join-Path -Path $SubScripts -ChildPath $UpdateVBFileName
							[string]$UpdateVBRemoteCommand = 'cscript.exe C:\WindowsScriptTemp\' + $UpdateVBFileName
												
							# SET INITIAL JOB SCOPE VARIBLES
							[boolean]$Failed = $false
							[boolean]$CompleteSuccess = $false
							[boolean]$RebootFailed = $false
							[Boolean]$RebootNeeded = $false
							[boolean]$AllPatchesInstalled = $false
							[boolean]$DiskSpaceOK = $false
							[int]$Global:RebootCount = '0'
							[int]$InstalledPatchesCount = '0'
							[int]$FailedPatchesCount = '0'
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
									New-Item -Path $RemoteShareRoot -name WindowsScriptTemp -ItemType directory -Force | Out-Null
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
									"\\$ComputerName\c$\WindowsPatching\SearchDownloadInstall-WUA.vbs",
									"\\$ComputerName\c$\WindowsPatching\SearchDownloadInstall-WUA_1.0.2.vbs",
									("\\$ComputerName\c$\WindowsPatching\" + $ComputerName + '_LastPatch.log'),
									"\\$ComputerName\c$\wuinstall.exe",
									"\\$ComputerName\c$\Update.vbs",
									("\\$ComputerName\c$\" +  $ComputerName + '_patchlog.txt'),
									"\\$ComputerName\c$\WindowsScriptTemp\Install-Patches_1.0.4.vbs"
								)
								# Remove each item in the filepaths array if exists
								ForEach ($filepath in $filepaths) {
									If ((Test-Path -Path $filepath) -eq $true) {
										Remove-Item -Path $filepath -Force 
									}
								}
							
							#endregion Temp: Remove Old Files

							#region Temp: Rename Old Logs
							
								$OldHistoryFileFullName = '\\' + $ComputerName + '\c$\WindowsScriptTemp\' + $ComputerName + '_PatchHistory.log'
								If ((Test-Path -Path $OldHistoryFileFullName) -eq $true) {
									Rename-Item -Path $OldHistoryFileFullName -NewName $HistoryLogFileName -Force
								}
							
							#endregion Temp: Rename Old Logs
							
							#region Create Blank Logs

								# CREATE BLANK LastPatches AND HISTORY LOG (need for check complete pattern string check)
								If ((Test-Path -Path $RemoteHistoryLogFullName) -eq $false) {
									New-Item -Path $RemoteShare -Name $HistoryLogFileName -ItemType file -Force | Out-Null
								}
								If ((Test-Path -Path $LocalHistoryLogFullName) -eq $false) {
									New-Item -Path $LocalHistoryLogPath -Name $HistoryLogFileName -ItemType file -Force | Out-Null
								}
							
							#endregion Create Blank Logs
							
							#region Add Script Log Header
							
								$DateTimeF = Get-Date -format g
								$ScriptLogData = @()
								$ScriptLogData += @(
									'',
									'',
									'',
									'******************************************************************************************',
									'******************************************************************************************',
									"JOB STARTED:     ($ComputerName) $DateTimeF $Timezone",
									"SCRIPT VER:      $ScriptVersion",
									"ADMINUSER:       $UserDomain\$UserName",
									"SCRIPTHOST:      $ScriptHost",
									"NO REBOOT:       $NoRebootBool"
								)
								
							#endregion Add Script Log Header
														
							#region Temp: Check and Change Log File Encoding as Needed
							
								$FileList = Get-ChildItem -Path "$RemoteShare\*.log"
								Foreach ($FileObject in $FileList) {
									$FullName = ($FileObject.FullName)
									Get-FileEncoding -FilePath $FullName
									
									If ($Global:GetFileEncoding.Success -eq $true) {
										If ($Global:GetFileEncoding.Encoding -ne 'ASCII') {
											# Get File Information
											$CreationTime = ($FileObject.CreationTime)
											$CreationTimeUtc = ($FileObject.CreationTimeUtc)
											$LastWriteTime = ($FileObject.LastWriteTime)
											$LastWriteTimeUtc = ($FileObject.LastWriteTimeUtc)
											$LastAccessTime = ($FileObject.LastAccessTime)
											$LastAccessTimeUtc = ($FileObject.LastAccessTimeUtc)
											
											# ADD RESULTS TO SCRIPT LOG ARRAY
											$Results = $null
											$Results = ($Global:GetFileEncoding | Format-List | Out-String).Trim('')
											$ScriptLogData += @(
												'',
												'GET FILE ENCODING BEFORE',
												'------------------------',
												"$Results"
											)
											Try {
												$Content = Get-Content -Path $FullName -ErrorAction Stop
												[Boolean]$ContentReceived = $true
											}
											Catch {
												[Boolean]$ContentReceived = $false
											}
											If ($ContentReceived -eq $true) {
												# Replace file with corrected character set
												Out-File -FilePath $FullName -Encoding ASCII -Force -InputObject $Content
												
												# Set original time stamp information on new file
												Set-ItemProperty -Path $FullName -Name CreationTime ($CreationTime)
												Set-ItemProperty -Path $FullName -Name CreationTimeUtc ($CreationTimeUtc)
												Set-ItemProperty -Path $FullName -Name LastWriteTime ($LastWriteTime)
												Set-ItemProperty -Path $FullName -Name LastWriteTimeUtc ($LastWriteTimeUtc)
												Set-ItemProperty -Path $FullName -Name LastAccessTime ($LastAccessTime)
												Set-ItemProperty -Path $FullName -Name LastAccessTimeUtc ($LastAccessTimeUtc)
											}
											
											#region Determine Results
											
												Get-FileEncoding -FilePath $FileObject.FullName
												# ADD RESULTS TO SCRIPT LOG ARRAY
												$Results = $null
												$Results = ($Global:GetFileEncoding | Format-List | Out-String).Trim('')
												$ScriptLogData += @(
													'',
													'GET FILE ENCODING AFTER REPLACEMENT',
													'-----------------------------------',
													"$Results"
												)
												If ($Global:GetFileEncoding.Success -eq $true) {
													If ($Global:GetFileEncoding.Encoding -eq 'ASCII') {
														$ScriptLogData += @(
															'',
															'LOG FILE REPLACEMENT: Successful'
														)
													}
												}
												Else {
													$ScriptLogData += @(
														'',
														'LOG FILE REPLACEMENT: Not Successful'
													)
												}
											
											#endregion Determine Results
										}
									} #IF Get File Encoding Success
								} #Foreach
							
							#endregion Temp: Check and Change Log File Encoding as Needed

						#endregion Setup Files and Folders

						#region Gather Remote System Information
						
							#region Get Hard Drive Space
							
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
										[string]$ScriptErrors += "Less Than Minimum Drive Space "
									}
									# SET RESULT VARIABLES
									[string]$FreeSpace = $Global:GetDiskSpace.FreeSpaceMB
									[string]$DriveSize = $Global:GetDiskSpace.DriveSize
									
									# DETERMINE RESULTS FOR LOG MIN SPACE
									If (($Global:GetDiskSpace.FreeSpaceMB) -ge '5') {
										[boolean]$LogDiskSpaceOK = $true
									}
									Else {
										[boolean]$LogDiskSpaceOK = $false
										[string]$ScriptErrors += "Not Enough Disk Space for Logs "
									}
								}
								Else {
									[boolean]$DiskSpaceOK = $false
									[boolean]$LogDiskSpaceOK = $false
									[string]$FreeSpace = 'N/A'
									[string]$DriveSize = 'N/A'
									[boolean]$Failed = $true
									[string]$ScriptErrors += $Global:GetDiskSpace.Notes
								}
								# IF SKIP DISK SPACE MIN CHECK BYPASS CONDITIONS
								If ($SkipDiskSpaceCheckBool -eq $false) {
									[Boolean]$DiskSpaceOK = $true
								}
								
							#endregion Get Hard Drive Space
						
							#region Get OS Version
							
								# ^NEED TO ADD ALTCREDS LOGIC
								Get-OSVersion -ComputerName $ComputerName -SkipVimQuery
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
								# WRITE RESULTS TO HISTORY LOGS LOGDATAARRAY
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
								# WRITE RESULTS TO HISTORY LOGS LOGDATAARRAY
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
							
								#region Check Pending
						
									# CHECK FOR PENDING REBOOT
									Get-PendingReboot -ComputerName $ComputerName -Assets $Assets
											
									# ADD RESULTS TO SCRIPT LOG ARRAY
									$Results = $null
									[array]$Results = ($Global:GetPendingReboot | Format-List | Out-String).Trim('')
									$ScriptLogData += @(
										'',
										'CHECK FOR PENDING REBOOT',
										'-------------------------',
										"$Results"
									)

									# REBOOT IF CHECK PENDING FAILS
									If ($Global:GetPendingReboot.Success -eq $false) {
										[boolean]$RebootNeeded = $true
										$RebootReason = 'Check Pending Safe Measure'
									}
									# REBOOT IF PENDING
									If ($Global:GetPendingReboot.Pending -eq $true) {
										[boolean]$RebootNeeded = $true
										$RebootReason = 'Pending Reboot Check'
									}
									If ($RebootNeeded -eq $true) {
										If ($NoRebootBool -eq $false) {
											# ADD TO SCRIPT LOG ARRAY
											$DateTimeF = Get-Date -format g
											$ScriptLogData += @(
												'',
												"REBOOTING:       [$ComputerName] for $RebootReason ($DateTimeF $TimeZone)"
											)
											
											Restart-Host -ComputerName $ComputerName
											$Global:RebootCount++
											$Global:RebootRuntimes += ' ' + $Global:RestartHost.RebootTime
											
											# ADD RESULTS TO SCRIPT LOG ARRAY
											$Results = $null
											[array]$Results = ($Global:RestartHost | Format-List | Out-String).Trim('')
											$ScriptLogData += @(
												'',
												'REBOOTING HOST',
												'--------------------------',
												"$Results"
											)
											# Determine Results
											If ($Global:RestartHost.Success -eq $true) {
												[Boolean]$RebootNeeded = $false
											}
											Else {
												[Boolean]$RebootNeeded = $true
												[Boolean]$RebootFailed = $true
												$ScriptErrors += 'Reboot Failure '
											}
										}
										Else {
											[Boolean]$RebootNeeded = $true
											$ScriptErrors += 'Pending Reboot '
										}
									}

								#endregion Check Pending
															
								#region Windows Patching
								
									If ($RebootNeeded -eq $false) {
										$DateTimeF = Get-Date -Format g
										
										#region Setup Logs and Assets
										
											# REMOVE LastPatches LOGS (So the script doesn't have a chance to pull old data)
											If ((Test-Path -Path $LocalLastPatchesLogFullName) -eq $true) {
												Remove-Item -Path $LocalLastPatchesLogFullName -Force | Out-Null
											}
											If ((Test-Path -Path $RemoteLastPatchesLogFullName) -eq $true) {
												Remove-Item -Path $RemoteLastPatchesLogFullName -Force | Out-Null
											}
											# IF Install-Patches.vbs MISSING THEN COPY TO CLIENT
											If ((Test-Path -Path $RemoteUpdateVB) -eq $False) {
												Copy-Item -Path $LocalUpdateVB -Destination $RemoteShare -Force | Out-Null 
											}
											
											# UPDATE HISTORY LOGS
											$DateTimeF = Get-Date -format g
											$ScriptLogData += @(
												'',
												'',
												"WINDOWS PATCHING STARTED:     ($DateTimeF $Timezone)",
												'******************************************************************************************'
											)
										
										#endregion Setup Logs and Assets
										
										#region Register VBS DLL on Remote Client
										
											Invoke-PSExec -ComputerName $ComputerName -Assets $Assets -Timeout '300' -RemoteCommand 'regsvr32.exe /s scrrun.dll'
											# ADD RESULTS TO SCRIPT LOG ARRAY
											$Results = $null
											$Results = ($Global:InvokePSExec | Format-List | Out-String).Trim('')
											$ScriptLogData += @(
												'',
												'REGISTER DLL FOR VBS SCRIPT ON REMOTE',
												'-------------------------------------',
												"$Results"
											)
										
										#endregion Register VBS DLL on Remote Client
									
										#region Patching Loop
										
											[int]$PatchingRounds = 0
											[int]$FailedInstalls = 0
											Do {
												$PatchingRounds++
												[boolean]$RemoteLastPatchesLogfound = $false
												[boolean]$AllPatchesInstalled = $false
												
												$DateTimeF = Get-Date -format g
												$ScriptLogData += @(
													'',
													'',
													"PATCHING LOOP ROUND $PatchingRounds ($DateTimeF $Timezone)",
													'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++',
													'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
												)
												
												#region Remove Latest Log
												
													If ((Test-Path -Path $LocalLastPatchesLogFullName) -eq $true) {
														Remove-Item -Path $LocalLastPatchesLogFullName -Force | Out-Null
													}
													If ((Test-Path -Path $RemoteLastPatchesLogFullName) -eq $true) {
														Remove-Item -Path $RemoteLastPatchesLogFullName -Force | Out-Null
													}
												
												#endregion Remove Latest Log
												
												#region Reboot if Failed Patches Once
												
													If ($FailedInstalls -eq '1') {
														If ($NoRebootBool -eq $false) {
															# ADD TO SCRIPT LOG ARRAY
															$DateTimeF = Get-Date -format g
															$ScriptLogData += @(
																'',
																"REBOOTING:       [$ComputerName] for Failed Patches ($DateTimeF $Timezone)"
															)
															
															#region Trigger Reboot
															
																Restart-Host -ComputerName $ComputerName
																$Global:RebootCount++
																$Global:RebootRuntimes += ' ' + $Global:RestartHost.RebootTime
																
																$Results = $null
																[array]$Results = ($Global:RestartHost | Format-List | Out-String).Trim('')
																$ScriptLogData += @(
																	'',
																	'REBOOTING HOST',
																	'--------------------------',
																	"$Results"
																)
																
																#region Determine Reboot Results
																
																	If ($Global:RestartHost.Success -eq $true) {
																		[Boolean]$RebootNeeded = $false
																	}
																	Else {
																		[Boolean]$RebootNeeded = $true
																		[Boolean]$RebootFailed = $true
																		$ScriptErrors += 'Reboot Failure '
																	}
																
																#endregion Determine Reboot Results
															
															#endregion Trigger Reboot
														}
														Else {
															[Boolean]$RebootNeeded = $true
															$ScriptErrors += 'Pending Reboot '
														}
													}
												
												#endregion Reboot if Failed Patches Once
												
												#region Check Pending After First Round
													
													If (($PatchingRounds -gt '1') -and ($RebootNeeded -ne $true)) {
														# CHECK FOR PENDING REBOOT
														Get-PendingReboot -ComputerName $ComputerName -Assets $Assets
												
														# ADD RESULTS TO SCRIPT LOG ARRAY
														$Results = $null
														[array]$Results = ($Global:GetPendingReboot | Format-List | Out-String).Trim('')
														$ScriptLogData += @(
															'',
															'CHECK FOR PENDING REBOOT',
															'-------------------------',
															"$Results"
														)

														# REBOOT IF CHECK PENDING FAILS
														If ($Global:GetPendingReboot.Success -eq $false) {
															[boolean]$RebootNeeded = $true
															$RebootReason = 'Check Pending Safe Measure'
														}
														# REBOOT IF PENDING
														If ($Global:GetPendingReboot.Pending -eq $true) {
															[boolean]$RebootNeeded = $true
															$RebootReason = 'Pending Reboot Check'
														}
														If ($RebootNeeded -eq $true) {
															If ($NoRebootBool -eq $false) {
																# ADD TO SCRIPT LOG ARRAY
																$DateTimeF = Get-Date -format g
																$ScriptLogData += @(
																	'',
																	"REBOOTING:       [$ComputerName] for $RebootReason ($DateTimeF $Timezone)"
																)
																
																#region Trigger Reboot
																
																	Restart-Host -ComputerName $ComputerName
																	$Global:RebootCount++
																	$Global:RebootRuntimes += ' ' + $Global:RestartHost.RebootTime
																	
																	$Results = $null
																	[array]$Results = ($Global:RestartHost | Format-List | Out-String).Trim('')
																	$ScriptLogData += @(
																		'',
																		'REBOOTING HOST',
																		'--------------------------',
																		"$Results"
																	)
																	
																	#region Determine Reboot Results
																	
																		If ($Global:RestartHost.Success -eq $true) {
																			[Boolean]$RebootNeeded = $false
																		}
																		Else {
																			[Boolean]$RebootNeeded = $true
																			[Boolean]$RebootFailed = $true
																			$ScriptErrors += 'Reboot Failure '
																		}
																	
																	#endregion Determine Reboot Results
																
																#endregion Trigger Reboot
															}
															Else {
																[Boolean]$RebootNeeded = $true
																$ScriptErrors += 'Pending Reboot '
															}
														}
													}
												
												#endregion Check Pending After First Round

#												#region Update Log with Patching Round Count
#												
#													$DateTimeF = Get-Date -format g
#													$ScriptLogData += @(
#														'',
#														"PATCHING:        [ROUND $PatchingRounds] ($DateTimeF $Timezone)"
#													)
#												
#												#endregion Update Log with Patching Round Count
												
												#region Install Patches
												
													#region Run Install Patches VBS on Remote
													
														If ($RebootNeeded -eq $false) {
															Invoke-PSExec -ComputerName $ComputerName -Assets $Assets -Timeout '5400' -RemoteCommand $UpdateVBRemoteCommand
														
															$Results = $null
															$Results = ($Global:InvokePSExec | Format-List | Out-String).Trim('')
															$ScriptLogData += @(
																'',
																'RUN WUAVBS SCRIPT ON REMOTE',
																'---------------------------',
																"$Results"
															)
														}
													
													#endregion Run Install Patches VBS on Remote
												
													#region Reboot and Retry if VBS Failed
													
														If (($Global:InvokePSExec.Success -eq $false) -and ($RebootNeeded -eq $false)) {
															# SETTING THAT A REBOOT IS NEEDED
															[Boolean]$RebootNeeded = $true
															If ($NoRebootBool -eq $false) {
																[string]$ScriptErrors += 'FAILED: WUVBS  REBOOT: WUVBS FAILURE  '

																$DateTimeF = Get-Date -format g
																$ScriptLogData += @(
																	'',
																	"REBOOTING:       [$ComputerName] for WU VBS SCRIPT FAILED ($DateTimeF $Timezone)"
																)
																
																#region Trigger Reboot
																
																	Restart-Host -ComputerName $ComputerName
																	$Global:RebootCount++
																	$Global:RebootRuntimes += ' ' + $Global:RestartHost.RebootTime
																	
																	$Results = $null
																	[array]$Results = ($Global:RestartHost | Format-List | Out-String).Trim('')
																	$ScriptLogData += @(
																		'',
																		'REBOOTING HOST',
																		'---------------',
																		"$Results"
																	)
																	
																	#region Determine Reboot Results
																	
																		If ($Global:RestartHost.Success -eq $true) {
																			[Boolean]$RebootNeeded = $false
																		}
																		Else {
																			[Boolean]$RebootNeeded = $true
																			[Boolean]$RebootFailed = $true
																			$ScriptErrors += 'Reboot Failure '
																		}
																	
																	#endregion Determine Reboot Results
																
																#endregion Trigger Reboot
																														
																#region Run Install Patches VBS on Remote Again
																
																	$DateTimeF = Get-Date -format g
																	$ScriptLogData += @(
																		'',
																		"WUAVBS:          [RUN] Retry after Reboot ($DateTimeF $TimeZone)"
																	)

																	Invoke-PSExec -ComputerName $ComputerName -Assets $Assets -Timeout '5400' -RemoteCommand $UpdateVBRemoteCommand
																	$Results = $null
																	$Results = ($Global:InvokePSExec | Format-List | Out-String).Trim('')
																	$ScriptLogData += @(
																		'',
																		'RUN WUAVBS SCRIPT ON REMOTE',
																		'---------------------------',
																		"$Results"
																	)
																
																#endregion Run Install Patches VBS on Remote Again
																
															} #NoReboot
															Else {
																[string]$ScriptErrors += 'Reboot Needed for VBS Failure '
															}
														} #Reboot if VBS Fails
												
													#endregion Reboot and Retry if VBS Failed
												
												#endregion Install Patches
												
												#region Determine VBS Success
												
													# SET EXIT COD INFO FOR RESULTS OUTPUT
													$WuVBSExitCode = $Global:InvokePSExec.ExitCode
													$WuVBSExitCodedesc = $Global:InvokePSExec.ExitCodeDesc | Out-String
													
													If ($Global:InvokePSExec.Success -eq $true) {
														[boolean]$RunVBSSuccess = $true
													}
													Else {
														[boolean]$Failed = $true
														[boolean]$RunVBSSuccess = $false
													}
												
												#endregion Determine VBS Success
												
												#region Process Latest Log
												
													If ($RunVBSSuccess -eq $true) {
													
														#region Copy Remote Latest Log

															$DateTimeF = Get-Date -format g
															$ScriptLogData += @(
																'',
																"PATCHING:        [COPYLOG] Loop Started ($DateTimeF $TimeZone)"
															)
															
															#region Copy Retry Loop
															
																[int]$CopyLogAttempts = 0
																Do {
																	$CopyLogAttempts++
																	[boolean]$RemoteLastPatchesLogfound = $false
																	[boolean]$LogCopyError = $true
																	[boolean]$LocalLastPatchesLogfound = $false
																	Try {
																		$DateTimeF = Get-Date -format g
																		$ScriptLogData += @(
																			'',
																			"PATCHING:        [COPYLOG] Test Path to Client LastPatches Log ($DateTimeF $TimeZone)"
																		)

																		[boolean]$RemoteLastPatchesLogfound = Test-Path -Path $RemoteLastPatchesLogFullName -ErrorAction Stop
																	}
																	Catch {
																		[boolean]$RemoteLastPatchesLogfound = $false
																	}
																	If ($RemoteLastPatchesLogfound -eq $true) {
																		Try {
																			# ADD TO SCRIPT LOG ARRAY
																			$DateTimeF = Get-Date -format g
																			$ScriptLogData += @(
																				'',
																				"PATCHING:        [COPYLOG] Copy Client LastPatches Log to Script Host ($DateTimeF $TimeZone)"
																			)

																			# COPY AND REPLACE Local LastPatches LOG WITH CLIENT LastPatches LOG
																			Copy-Item -Path $RemoteLastPatchesLogFullName -Destination $LocalLastPatchesLogPath -Force | Out-Null -ErrorAction Stop
																			[boolean]$LogCopyError = $false
																		}
																		Catch {
																			[boolean]$LogCopyError = $true
																		}
																		If ($LogCopyError -eq $false) {
																			# TEST IF FILE IS ON Script HOST
																			Try {
																				# ADD TO SCRIPT LOG ARRAY
																				$DateTimeF = Get-Date -format g
																				$ScriptLogData += @(
																					'',
																					"PATCHING:        [COPYLOG] Test Path to Local LastPatches Log ($DateTimeF $TimeZone)"
																				)
																				
																				$LocalLastPatchesLogfound = Test-Path -Path $LocalLastPatchesLogFullName -ErrorAction Stop
																			}
																			Catch {
																				[boolean]$LocalLastPatchesLogfound = $false
																			}
																		}
																		Else {
																			Sleep -Seconds 1
																		}
																	}
																	Else {
																		Sleep -Seconds 1
																	}
																}
																Until (($LocalLastPatchesLogfound -eq $true) -or ($CopyLogAttempts -ge 900))
														
															#endregion Copy Retry Loop
														
															$DateTimeF = Get-Date -format g
															$ScriptLogData += @(
																'',
																"PATCHING:        [COPYLOG] Loop Ended ($DateTimeF $TimeZone)",
																'',
																"PATCHING:        [COPYLOG] Copy Log Loop Count: $CopyLogAttempts ($DateTimeF $TimeZone)"
															)
														
														#endregion Copy Remote Latest Log
														
														#region Process Latest Log Data
														
															If ($LocalLastPatchesLogfound -eq $true) {
																
																#region Update Log Array
																
																	$DateTimeF = Get-Date -format g
																	$ScriptLogData += @(
																		'',
																		"PATCHING:        [CHECKLOG] Found Local LastPatches Log ($DateTimeF $TimeZone)"
																	)
																	
																	[array]$PatchLogData = Get-Content -Path $LocalLastPatchesLogFullName
																	[int]$LogLineCount = $PatchLogData.Count
																	If ($PatchLogData) {
																		$DateTimeF = Get-Date -format g
																		$Results = $null
																		$Results = $PatchLogData | Out-String
																		$ScriptLogData += @(
																			'',
																			"LAST PATCHES LOG DATA ($DateTimeF $TimeZone)",
																			'**************************************************************',
																			'',
																			"$Results",
																			'',
																			'**************************************************************'
																		)
																	}
																	
																	$DateTimeF = Get-Date -format g
																	$ScriptLogData += @(
																		'',
																		"PATCHING:        [CHECKLOG] Local LastPatches Log Line Count = $LogLineCount ($DateTimeF $TimeZone)"
																	)

																	If ($LogLineCount -le 1) {
																		[boolean]$LastPatchesLogEmpty = $true

																		$DateTimeF = Get-Date -format g
																		$ScriptLogData += @(
																			'',
																			"PATCHING:        [CHECKLOG] ERROR: Local LastPatches Log is Empty ($DateTimeF $TimeZone)"
																		)
																	}
																	Else {
																		[boolean]$LastPatchesLogEmpty = $false
																		
																		$DateTimeF = Get-Date -format g
																		$ScriptLogData += @(
																			'',
																			"PATCHING:        [CHECKLOG] Local LastPatches Log is not Empty ($DateTimeF $TimeZone)"
																		)
																	}
																
																#endregion Update Log Array
																
																#region Get Patching Results
																
																	[array]$Patches = @()
																	[array]$SuccessfulPatches = @()
																	[array]$FailedPatches = @()
																	
																	[array]$Patches = $PatchLogData | Where-Object {$_ -like "*>*"}
																	[array]$SuccessfulPatches = $Patches | Where-Object {$_ -like '*: 2'}
																	[array]$FailedPatches = $Patches | Where-Object {$_ -like '*: 4'}
																	
																	# FAIL AFTER PATCHES FAILED, REBOOTED, and FAILED AGAIN 
																	# UNLESS NO REBOOT SWITCH ACTIVE THEN SET TO BAIL
																	If ($FailedPatches -ne $null) {
																		If ($NoRebootBool -eq $true) {
																			# THIS WILL BUMP THE COUNT TO 1 SO IT BAILS OUT WITHOUT
																			#  ATTEMPTING A REBOOT AS A POSSIBLE FIX FOR THE FAILED PATCHES
																			$FailedInstalls++
																		}
																		If ($FailedInstalls -gt 0) {
																			#Look for “KB + only numbers”
																			$RegEx = 'KB\d*'
																			[array]$FailedKBArray = @()
																			Foreach ($Patch in $FailedPatches) {
																				$Patch -match $RegEx | Out-Null
																				$FailedKBArray += $Matches.Values
																			}
																			
																			[string]$FailedKBList = $null
																			Foreach ($KB in $FailedKBArray) {
																				[string]$FailedKBList += $KB + ' '
																			}
																			[string]$ScriptErrors += "FAILED: $FailedKBList "
																			[int]$FailedPatchesCount = $FailedPatches.Count
																		}
																		$FailedInstalls++
																	}
																	Else {
																		# THIS IS TO RESET IF A REBOOT FIXED THE CURRENT FAILED PATCHES
																		[int]$FailedInstalls = 0
																	}

																	[int]$InstalledPatchesCount += $SuccessfulPatches.Count
																	[boolean]$AllPatchesInstalled = Select-String -Pattern 'No updates to install.' -Path $LocalLastPatchesLogFullName -Quiet
																
																#endregion Get Patching Results
																
																#region Determine if Reboot Needed from Latest Log
																
																	If ($LastPatchesLogEmpty -eq $false) {
																		# Read admin LastPatches log file to see if a reboot is required 
																		# Using the -Quiet switch makes the cmdlet return a True of False if it finds the string
																		[Boolean]$RebootLogCheck = Select-String -Pattern 'Reboot Required: True' -Path $LocalLastPatchesLogFullName -Quiet
																		
																		If ($RebootLogCheck -eq $true) {
																			[Boolean]$RebootNeeded = $true
																		}
																		
																		#region Reboot if Needed
																		
																			If ($RebootLogCheck -eq $true) {
																				If ($NoRebootBool -eq $false) {
																					$DateTimeF = Get-Date -format g
																					$ScriptLogData += @(
																						'',
																						"REBOOTING:       [$ComputerName] for Windows Patching Required Reboot ($DateTimeF $TimeZone)"
																					)
																					
																					#region Trigger Reboot
																					
																						Restart-Host -ComputerName $ComputerName
																						$Global:RebootCount++
																						$Global:RebootRuntimes += ' ' + $Global:RestartHost.RebootTime
																						
																						# ADD RESULTS TO SCRIPT LOG ARRAY
																						$Results = $null
																						[array]$Results = ($Global:RestartHost | Format-List | Out-String).Trim('')
																						$ScriptLogData += @(
																							'',
																							'REBOOTING HOST',
																							'--------------------------',
																							"$Results"
																						)
																					
																						#region Determine Reboot Results
																						
																							If ($Global:RestartHost.Success -eq $true) {
																								[Boolean]$RebootNeeded = $false
																							}
																							Else {
																								[Boolean]$RebootNeeded = $true
																								[Boolean]$RebootFailed = $true
																								$ScriptErrors += 'Reboot Failure '
																							}
																						
																						#endregion Determine Reboot Results
																					
																					#endregion Trigger Reboot
																					
																				} # NOREBOOT
																				Else {
																					$ScriptErrors += 'Reboot Needed for Installed Patches '
																				}
																			}
																			Else {
																				# ADD TO SCRIPT LOG ARRAY
																				$DateTimeF = Get-Date -format g
																				$ScriptLogData += @(
																					'',
																					"PATCHING:        [CHECK PENDING] Reboot not required ($DateTimeF $TimeZone)"
																				)
																			}
																		
																		#endregion Reboot if Needed
																		
																	} #Check if Reboot Needed from Latest Log
																	Else {
																		$ScriptErrors += 'Latest Log Empty '
																	}
																
																#endregion Determine if Reboot Needed from Latest Log
																
															} # LastPatches Log Copied to Admin Host
															ElseIf ($CopyLogAttempts -ge 900) {
																[boolean]$Failed = $true
																$ScriptErrors += 'Latest Log Not Found '
																[boolean]$RemoteLastPatchesLogfound = $false
																
																# ADD TO SCRIPT LOG ARRAY
																$DateTimeF = Get-Date -format g
																$ScriptLogData += @(
																	'',
																	"PATCHING:        [ERROR] PATCH LOG MISSING ($DateTimeF $TimeZone)"
																)
															}
														
														#endregion Process Latest Log Data
														
													} # IF WUAVBS Success
												
												#endregion Process Latest Log
												
												#region Determine if No Reboot Escape Needed
												
													If (($RebootNeeded -eq $true) -and ($NoRebootBool -eq $true)) {
														[Boolean]$NoRebootBail = $true
													}
													Else {
														[Boolean]$NoRebootBail = $false
													}
												
												#endregion Determine if No Reboot Escape Needed
											} 	
											# DO Windows Patching Loop Until: It has Looped 4 Times OR The Admin LastPatches Log has "No Updates to Install" string OR Reboot Failed OR Client LastPatches Patch Log not found OR Client LastPatches Patch Log is empty
											Until (($AllPatchesInstalled -eq $true) -or ($PatchingRounds -ge 8) -or ($RebootFailed -eq $true) -or ($RemoteLastPatchesLogfound -eq $false)-or ($LastPatchesLogEmpty -eq $true) -or ($RunVBSSuccess -eq $false) -or ($NoRebootBail -eq $true) -or ($FailedInstalls -gt '1'))
											
										#endregion Patching Loop
										
										#region Determine Patching Loop Exit Reason
										
											# The order matters because of false positives if bails
											If ($AllPatchesInstalled -eq $true) {
												$PatchLoopExitReason = 'No updates to install'
											}
											Elseif ($RunVBSSuccess -eq $false) {
												$PatchLoopExitReason = 'Windows Update VBS Script Failed'
												[boolean]$Failed = $true
											}
											Elseif ($PatchingRounds -ge 8) {
												$PatchLoopExitReason = 'Over Patching Round Limit (8)'
												[boolean]$Failed = $true
											}
											Elseif ($RebootFailed -eq $true) {
												$PatchLoopExitReason = 'Reboot Failed'
												[boolean]$Failed = $true
											}
											Elseif ($RemoteLastPatchesLogfound -eq $false) {
												$PatchLoopExitReason = 'Remote LastPatches Log Not Found'
												[boolean]$Failed = $true
											}
											Elseif ($LastPatchesLogEmpty -eq $true) {
												$PatchLoopExitReason = 'Remote LastPatches Log is Empty'
												[boolean]$Failed = $true
											}
											Elseif ($NoRebootBail -eq $true) {
												$PatchLoopExitReason = 'No Reboot Switch used. So only one round was executed.'
												[boolean]$Failed = $true
											}
											Elseif ($FailedInstalls -gt '1') {
												$PatchLoopExitReason = 'Failed Patches twice in a row.'
												[boolean]$Failed = $true
											}

											# Update Log
											$DateTimeF = Get-Date -format g
											$ScriptLogData += @(
												'',
												"PATCHING:        [PATCH LOOP] EXIT REASON: $PatchLoopExitReason ($DateTimeF $TimeZone)"
											)
										
										#endregion Determine Patching Loop Exit Reason
										
									} #RebootNeeded
									
								#endregion Windows Patching
								
								#region Check Pending and Reboot if Needed
								
									If (($AllPatchesInstalled -eq $true) -and ($RebootFailed -ne $true) -and ($RebootNeeded -eq $false)) {
										# CHECK FOR PENDING REBOOT
										Get-PendingReboot -ComputerName $ComputerName -Assets $Assets
										
										# ADD RESULTS TO SCRIPT LOG ARRAY
										$Results = $null
										[array]$Results = ($Global:GetPendingReboot | Format-List | Out-String).Trim('')
										$ScriptLogData += @(
											'',
											'CHECK FOR PENDING REBOOT',
											'-------------------------',
											"$Results"
										)

										[boolean]$Reboot = $false
										# REBOOT IF CHECK PENDING FAILS
										If ($Global:GetPendingReboot.Success -eq $false) {
											[boolean]$Reboot = $true
											$RebootReason = 'Check Pending Safe Measure'
										}
										# REBOOT IF PENDING
										If ($Global:GetPendingReboot.Pending -eq $true) {
											[boolean]$Reboot = $true
											$RebootReason = 'Pending Reboot Check'
										}
										If ($Reboot -eq $true) {
											If ($NoRebootBool -eq $false) {
												$DateTimeF = Get-Date -format g
												$ScriptLogData += @(
													'',
													"REBOOTING:       [$ComputerName] for $RebootReason ($DateTimeF $TimeZone)"
												)
												
												#region Trigger Reboot
												
													Restart-Host -ComputerName $ComputerName
													$Global:RebootCount++
													$Global:RebootRuntimes += ' ' + $Global:RestartHost.RebootTime
													
													# ADD RESULTS TO SCRIPT LOG ARRAY
													$Results = $null
													[array]$Results = ($Global:RestartHost | Format-List | Out-String).Trim('')
													$ScriptLogData += @(
														'',
														'REBOOTING HOST',
														'--------------------------',
														"$Results"
													)
													
													#region Determine Reboot Results
													
														If ($Global:RestartHost.Success -eq $true) {
															[Boolean]$RebootNeeded = $false
														}
														Else {
															[Boolean]$RebootNeeded = $true
															[Boolean]$RebootFailed = $true
															$ScriptErrors += 'Reboot Failure '
														}
													
													#endregion Determine Reboot Results
												
												#endregion Trigger Reboot
											}
											Else {
											[Boolean]$RebootNeeded = $true
											$ScriptErrors += 'Pending Reboot '
											}
										}
									}
												
								#endregion Check Pending and Reboot if Needed
								
							} # If Diskspace OK and reboot didn't fail, Else Bailout but finish Output Report
						
						#endregion Main Tasks
						
						#region Generate Report
							
							#region Determine Results
							
								If ($Global:RebootRuntimes) {
									[string]$RebootRuntimes = $Global:RebootRuntimes
								}
								Else {
									[string]$RebootRuntimes = 'N/A'
								}
								If ($RebootFailed -eq $true) {
									[string]$ScriptErrors += 'FAILED: Reboot  '
								}
								If ($RemoteLastPatchesLogfound -eq $false) {
									[string]$ScriptErrors += 'FAILED: Get LastPatches Log  '
								}
								If ($LastPatchesLogEmpty -eq $true) {
									[string]$ScriptErrors += 'ERROR: LastPatches Log Empty  '
								}
								If ($RunVBSSuccess -eq $false) {
									[string]$ScriptErrors += 'FAILED: WUVBS  '
								}
								# COMPLETE SUCCESS
								
								If ($RebootNeeded -eq $true) {
									[boolean]$CompleteSuccess = $false
								}
								ElseIf ($Failed -eq $false) {
									[boolean]$CompleteSuccess = $true
								}
								Else {
									[boolean]$CompleteSuccess = $false
								}
							    # DETERMINE PATCHING RESULTS
								If ($AllPatchesInstalled -eq $true) {
									$PatchingResults = 'All Patches Installed Successfully'
								}
								ElseIf (($InstalledPatchesCount -gt 0) -and ($RebootNeeded -eq $true)) {
									$PatchingResults = 'Some but not all Patches were Installed Successfully. System is Pending Reboot'
								}
								ElseIf (($InstalledPatchesCount -eq 0) -and ($RebootNeeded -eq $true)) {
									$PatchingResults = 'No Patches were installed. System is Pending Reboot'
								}
								Else {
									$PatchingResults = 'Failed Windows Patching'
								}
								
							#endregion Determine Results

							#region Set Results if Missing
							
								If (!$OSVersion) {
									[string]$OSVersion = 'Unknown'
								}
								If (!$OSArch) {
									[string]$OSArch = 'Unknown'
								}
								If (!$HostIP) {
									[string]$HostIP = 'Unknown'
								}
								If (!$DriveSize) {
									[string]$DriveSize = 'Unknown'
								}
								If (!$FreeSpace) {
									[string]$FreeSpace = 'Unknown'
								}
								If (!$WuVBSExitCode) {
									[string]$WuVBSExitCode = 'N/A'
								}
								If (!$ScriptErrors) {
									[string]$ScriptErrors = 'None'
								}
							
							#endregion Set Results if Missing

							#region Output Results to File

								Get-Runtime -StartTime $JobStartTime #Results used Log Footer section too
								[string]$TaskResults = $ComputerName + ',' + $CompleteSuccess + ',' + $AllPatchesInstalled + ',' + $DiskSpaceOK + ',' + $InstalledPatchesCount + ',' + $FailedPatchesCount + ',' + $Global:RebootCount + ',' + $RebootNeeded + ',' +$ConnectSuccess + ',' + $Global:GetRuntime.Runtime + ',' + $JobStartTime + ' ' + $TimeZone + ',' + $Global:GetRuntime.EndTimeF + ' ' + $TimeZone + ',' + $OSVersion + ',' + $OSArch + ',' + $HostIP + ',' + $HostDomain + ',' + $DriveSize + ',' + $FreeSpace + ',' + $RebootRuntimes + ',' + $WuVBSExitCode + ',' + $ScriptErrors + ',' + $ScriptVersion + ',' + $ScriptHost + ',' + $UserName
								
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
										Sleep -Milliseconds 300
										# Could write to ScriptLog which error is caught
									}
									# ANY OTHER EXCEPTION
									Catch {
										[boolean]$ErrorFree = $false
										Sleep -Milliseconds 300
										# Could write to ScriptLog which error is caught
									}
								}
								# Try until writes to output file or 
								Until (($ErrorFree -eq $true) -or ($LoopCount -ge '150'))
							
							#endregion Output Results to File
							
							#region Add Script Log Footer
							
								# ADD TO SCRIPT LOG ARRAY
								$DateTimeF = Get-Date -format g
								$ScriptLogData += @(
									'',
									"OUTPUT:          [WRITING] Attempts = $LoopCount ($DateTimeF $TimeZone)",
									'',
									"OUTPUT:          [WRITING] Finished ($DateTimeF $TimeZone)"
								)
								# ADD TO SCRIPT LOG ARRAY
								$Runtime = $Global:GetRuntime.Runtime
								$DateTimeF = Get-Date -format g
								$ScriptLogData += @(
									'',
									'',
									'',
									"WINDOWS PATCHING: $PatchingResults",
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
						
							# REMOVE WIP OBJECT FILE
							If ((Test-Path -Path "$WIPTempPath\$ComputerName") -eq $true) {
								Remove-Item -Path "$WIPTempPath\$ComputerName" -Force
							}
						
						#endregion Remove WIP File

					} -ArgumentList $ComputerName,$SubScripts,$Assets,$ScriptVersion,$JobLogFullName,$MinFreeMB,$SkipDiskSpaceCheckBool,$UserDomain,$UserName,$ScriptHost,$FileDateTime,$LogPath,$ResultsTextFullName,$ResultsTempPath,$WIPTempPath,$NoRebootBool,$TimeZone | Out-Null
				
				#endregion Background Job
				# PROGRESS COUNTER
				$i++
			} #/Foreach Loop
		
		#endregion Job Loop

		Show-ScriptHeader -BlankLines '4' -DashCount $DashCount -ScriptTitle $ScriptTitle
		# POST TOTAL HOSTS SUBMITTED FOR JOBS
		Show-ScriptStatusJobsQueued -JobCount $TotalHosts
		
	#endregion Job Tasks
		
	#region Job Monitor
	
		Get-JobCount
		Set-WinTitleJobCount -WinTitleInput $Global:WinTitleInput -JobCount $Global:getjobcount.JobsRunning
		
		# Job Monitoring Function Will Loop Until Timeout or All are Completed
		Watch-Jobs -JobLogFullName $JobLogFullName -Timeout $JobQueTimeout -Activity "INSTALLING PATCHES" -WinTitleInput $Global:WinTitleInput
		
	#endregion Job Monitor

#region Cleanup WIP

	# GATHER LIST AND CREATE RESULTS FOR COMPUTERNAMES LEFT IN WIP
	If ((Test-Path -Path "$WIPTempPath\*") -eq $true) {
		Get-Runtime -StartTime $ScriptStartTime
		[string]$TimedOutResults = 'False,False,Unknown,Unknown,Unknown,Unknown,Unknown,True' + ',' + $Global:GetRuntime.Runtime + ',' + $ScriptStartTimeF + ' ' + $TimeZone + ',' + $Global:GetRuntime.EndTimeF + ' ' + $TimeZone + ',' + "Unknown,Unknown,Unknown,Unknown,Unknown,Unknown,Unknown,Unknown,Timed Out" + ',' + $ScriptVersion + ',' + $ScriptHost + ',' + $UserName

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
		"All Patches Installed",
		"DiskSpace OK",
		"Installed",
		"Failed",
		"Reboots",
		"Reboot Needed",
		"Connected",
		"Runtime",
		"Starttime",
		"Endtime",
		"OSVersion",
		"OSArch",
		"HostIP",
		"Host Domain",
		"C: Size (MB)",
		"C: Free (MB)",
		"Reboot Times",
		"WUVBS Exitcode",
		"Errors",
		"Script Version",
		"Script Host",
		"User"
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
	Show-ScriptStatusRuntimeTotals -StartTimeF $ScriptStartTimeF -EndTimef $Global:GetRuntime.Endtimef -Runtime $Global:GetRuntime.Runtime
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
		$OutFile | Out-GridView -Title "Windows Patching Results for $InputItem"
	}

#endregion Display Report

#region Cleanup UI

	Reset-WindowsPatchingUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables

#endregion Cleanup UI

} #Function

#region Notes

<# Dependants
	None
#>

<# Dependencies
Get-Runtime
Remove-Jobs
Get-JobCount
Watch-Jobs
MultiStopWatch
MultiSet-WinTitle
MultiShow-Script-Status
Add-HostToLogFile
Get-PendingReboot
Get-DiskSpace
Get-HostIP
Get-IPconfig
Get-OSVersion
Get-RegValue
Restart-Host
Invoke-PSExec
Test-Connections
Reset-WindowsPatchingUI
ConvertTo-ASCII
Multi_Write-Logs
Install-Patches.vbs
#>

<# Change Log

2.0.0 - 04/08/2011 (Alpha)
	Moved directory location to C:\Scripts\Windows-Patching. Pulled data sections and pasted 
	into my jobloop script template. 
2.0.0 - 04/11/2011
	Continued cleanup and started testing in new template format.  
	Got most of the basic bugs worked out.
2.0.0 - 04/12/2011
	Continued reformatting and splitting code off to external files.
	Started logic build for summary CSV Results file.
2.0.1 - 04/13/2011
	Moved and cleaned up Prompt for Missing Host Input to top because the varible consolidation
	broke the setting of the path variables for the host inputs.
2.0.1 - 04/20/2011
	Fixed StartTimeF variable to not call globally
2.0.2 - 04/22/2011
	Cleaned up information sections and changed to new format.
2.0.3 - 04/27/2011
	Added Method ToUpper on Hosts to make them always uppercase.
2.0.6 - 05/05/2011
	Changed PSVersion to new PSObject global variable.
	Added conversion of Results text file to csv.
	Changed Get-DiskSpace $minfree to $MinFreeMB
2.0.7 - 05/05/2011
	Added Out-GridView at end
2.0.8 - 05/08/2011
	Changed Results to include more diskcheck info.
2.0.9 - 05/13/2011
	Removed extra vCenter var setting.
2.1.0 - 05/13/2011
	Fixed History Log Append from Latest Log in Run-Patching
	Added Adminhost and UserName to Results file
2.1.1 - 07/18/2011
	Moved MaxJobs to Parameter.
	Increased the max jobs default from 120 to 200
2.1.2 - 09/14/2011
	Fixed it so it will allow Vmware PowerCLI version 5.x
2.1.3 - 10/02/2011
	Added Vmtools and VmHardware version to Results
2.1.4 - 10/05/2011
	Added Script Version, Host IP and VMDatastores header to Results file
2.1.5 - 10/09/2011
	Troubleshooting Latest Log missing patches
	Combined Host Method and Log File Name to one section
	Added Dependencies path check at start
	Removed subfolders for input Lists
2.1.6 - 10/09/2011
	Removed Ordered FileList and FileList
2.1.7 - 10/09/2011
	Added $Global:HostList so it only runs the trimmed down List not including ComputerNames that failed the Test-Permissions Function
2.1.8 - 10/09/2011
	Moved the Test Permissions and Run Patching to single lines following the hostmethod variable setting
2.1.9 - 10/11/2011
	Fixed up Total Hosts
	Fixed up Test Permissions host console writes
	Added Dependants Get-HostIP and Get-VmGuestInfo
2.2.0 - 10/13/2011
	Removed Second Reboot failure in Results file header
	Rearranged Results header columns
	Added Clientlatest log empty and found to Results header
2.2.1 - 10/13/2011
	Switched Update.vbs to SearchDownloadInstall-WUA.vbs dependency check
2.2.2 - 11/04/2011
	Cleaned up some code for InputItem at end to remove redundant code.
	Indented regions for easier viewing.
2.2.3 - 11/04/2011
	Added specific variable types
	Consolidated InputItem, filename, hostmethod and HostList creation up top in Variables
	Changed Hostfile to FileName
	Removed hostmethod
	Added ArrayList Parameter and logic to feed an array or List of hostnames to the cmdlet without a file
	Split the Change log up so I can Min the 1.x stuff
	Fixed some upper case stuff in the HostList creation and InputItem set
2.2.4 - 11/04/2011
	Added missing $List $f filename variable
2.2.5 - 11/07/2011
	Fixed Missing input prompt to work with new List parameter
	Increase default jobmax to 320
2.2.6 - 11/07/2011
	Changed to use 64-bit PowerShell so Pending Reboot .NET object can check both 32 and 64 registries.
2.2.7 - 11/10/2011
	Changed back to 32-bit PowerShell check
	Changed to Run-patching 1.2.0
	Now using .NET 4.0 in PowerShell to solve the Get-PendingReboot issue with looking up 64-bit registrys
	Added back VICREDS option
2.2.8 - 11/10/2011
	Working out credintials issue
	Removed VIC parameter (not needed)
	Changed Sub Scripts to new version naming
2.2.9 - 11/11/2011
	Changed to all the sub scripts that use Connect-VIHost_1.0.3 to newer version
	Including Run-Patching to 1.2.1
2.3.0 - 11/21/2011
	Cleaned up some code
	Changed to Run-Patching_1.2.2
2.3.1 - 01/31/2012
	Changed to Run-Patching_1.2.3
2.3.2 - 01/31/2012
	Changed Run-Patching to 1.2.4
	Updated Remove-Jobs to 1.0.3
	Updated Watch-Jobs to 1.0.1
	Updated Get-JobCount to 1.0.2
	Added Test-Connection SubScript and replace Test-Permissions section
	Removed Test-Permissions SubScript
2.3.2 - 02/03/2012
	Removed completesuccesslog
2.3.3 - 02/03/2012
	Changed Run-Patching to 1.2.5
	Added Failed_Access Path and Filename
	Update MultiOut-ScriptLog_1.0.2
	Added all missing parameters for Out-ScriptLog-Header
2.3.3 - 02/07/2012
	Added spacing at end of Show-ScriptHeader for new Progress bars
	Finished removing all the extra failed logs
	Added $psversion + rename $psver to $psversion
	Added $CLRVersion
	Updated to Multi_Wintitle-Display_1.0.3
	Updated to Watch-Jobs_1.0.1
2.3.4 - 02/07/2012
	Added blank line logic and parameter to change the spacing for when the progress bar is visable
	to Show-ScriptHeader local function.
	Changed Set-WinTitleNotice to Set-WinTitleStart
2.3.5 - 02/07/2012
	Changed Script Completion Updates section at end so that it will finish with the Results and
	complete the script. Some or most may have been ok and it was just hung on a few.
2.3.6 - 02/08/2012
	Still tracking down the error at the end in the Job Cleanup
	Found it! It was the Receive-Job (data) that had "errors" in the Results from
		the psexec Results that would stop the script with $ErrorActionPreference = "Inquire" set
		because even though they were "ok" errors (returned error 0) it still saw it as an error
		and would flag. So I added -ErrorAction ContinueSilently to the Receive-Job action
		in Job-Cleanup_1.0.3 subscript.
	Removed PSExec.exe path variables
	Replace PSExec lines with newly built subscript Invoke-PSExec_1.0.1
	Updated to Run-Patching_1.2.6 that has PSExec method changed
2.3.7 - 02/09/2012
	Changed WUScript Success to WUAVBS Success header title on Results file.
2.3.8 - 02/09/2012
	Updated to Run-Patching_1.2.7 batch file to run VB Script
2.3.9 - 02/09/2012
	Updated to Run-Patching_1.2.8 Cleanup UI Results
2.4.0 - 02/10/2012
	Updated to Run-Patching_1.2.9
2.4.1 - 02/10/2012
	Updated to Run-Patching_1.3.0
2.4.2 - 02/10/2012
	Changed $outfile for CSV back to pipe into $outfile | Export-Csv -Path $ResultsCSVFullName -NoTypeInformation
2.4.3 - 02/10/2012
	Converted Show-ScriptHeader Local Function to subscript Function
	Updated to Run-Patching_1.3.1 (Using net Show-ScriptHeader Subscript)
2.4.4 - 04/16/2012
	Renamed several variables
	Change _Shared-Dependencies to _SubScripts
	Cleaned up Parameter case.
	Change $hdc variable to $GetDiskSpace switch.
	Changed log formatting to better layout.
	Moved CheckFreeSpace prompt to under if missing host input
	Switched to Run-Patching_1.3.2
	Switched to Add-Header_1.0.1
	Added $DashCount to parent script and pass to Run-Patching subscript
	Added GetVmHardware and GetVmTools switch parameters. need logic
2.4.5 - 04/16/2012
	Changed CheckFreeSpace to SkipDiskSpaceCheck
	Changed GetVmHardware and GetVmTools to Skip
	Added UseAltViCreds switch Parameter
2.4.6 - 04/19/2012
	SubScript renames
	Removed Multi_Check-JobLoopScript-Parameters subscript
	Removed Get-PSVersion subscript
	Switched to Run-Patching_1.3.5
	Switched to Test-Connections_1.0.1
		Added Show-ScriptHeader parameters
2.4.7 - 04/20/2012
	Switch to Run-Patching_1.3.7
	Renamed parameter FileName to FileName
2.4.9 - 04/20/2012
	Switch to Run-Patching_1.3.8
	More renaming parameters and tweaking new log method
2.5.0 - 04/23/2012
	Moved Results columns around and renamed some
	Switched to Run-Patching_1.3.9
2.5.1 - 04/24/2012
	Changed Title. Noticed having the script version was redundant since I added it to the Console title.
2.5.2 - 04/25/2012
	Turned parent script into function so can be used in module
	Added position 0 to ComputerName
	Added Cleanup section at end and start
2.5.3 - 04/26/2012
	Renamed a ton more through all scripts to conform with approved cmdlet verbs. Working towards
	all sub scripts to be contained in WindowsPatching Module.
	Added switch to skip Out-Gridview
2.5.4 - 04/27/2012
	Changed Cleanup Section to Reset-WindowsPatchingUI subscript.
2.5.6 - 04/30/2012
	Host Method Prompt cleanup and changes.
	Added several Do Until loops in prompts.
	Added Get-FileNames File Browser for FileName.
	Fixed Alt Creds prompt (Condition was backwards).
	Removed vcenter parameter default.
	Added vCenter FQDN prompt.
	Added FileBrowse Switch and draft logic.
	Changed name of altvicreds to usealtvicreds
	Changed name of usealtvicreds to usealtvicredsbool
	Added UseAltPCCreds parameter
	Added UseAltPCCredsBool variable
	Added PCCreds variable and draft logic
	Changed AltViCreds to ViCreds variable
2.5.8 - 05/03/2012
	Changed folder locations and some names using Set-WindowsPatchingDefault Global variable.
	Changed Windows-Patching to WindowsPatching remote folder
	Added remove / copy logs of Windows-Patching folder on remote system
	Renamed a lot of variables so they make more since and continued improvement on my own stardards
	Fixed some rename mistakes such as ConnectToViHost to ConnectViHost
	Changed Set-Header to Show-ScriptHeader
	Added Error handling at start for if Set-WindowsPatchingDefaults wasn't ran
	Fixed Out-ScriptLog-Error
	Added Out-ScriptLog-Errors specifically for writing $Error to log, may not need it
	Added Show-ScriptStatusFiles function to give path to output files and folders
2.5.9 - 05/07/2012
	Renamed Get-FileName to Get-FileName and moved to SubScripts
	Changed the module to not load Get-FileName and have the scripts call it if needed.
2.6.0 - 05/08/2012
	Added JobQueTimeout parameter
	Switch to Invoke-patching 1.4.6 that now includes the JobQueTimeout parameter as well
	Tweaked the Maxjobs and JobQueTimeouts to be more efficient
	Added WIP file cleanup for it Watch-Jobs Timeout.
	Switched to Test-Connections 1.0.4
	Switched to Watch-Jobs 1.0.3
	Added Get-TimeZone to pull localhost timezone for file names.
2.6.1 - 05/10/2012
		Renamed Reset-UI to Reset-WindowsPatchingUI
2.6.2 - 05/11/2012
	Fixed Prompt for AltViCreds. It needed to be outside Missing Host Vmware Prompt Group.
2.6.3 - 05/14/2012
	Switched to Show-WPMTip 1.0.2
2.6.3 - 05/15/2012
	Added Hosts that failed connection test to Results.
	Switched to Invoke-Patching 1.4.7
2.6.4 - 05/16/2012
	Switched to Get-OSVersion 1.0.9
	Switched to Invoke-Patching 1.4.8
	Removed FailedAccess logic now that it's in the results.
	Switched to Test-Connections 1.0.6
2.6.5 - 07/26/2012
	Switched to Invoke-Patching 1.4.9
2.6.6 - 07/30/2012
	Switched to Invoke-PSExec 1.0.8 depcheck
	Switched to Invoke-Patching 1.5.0
	Switched to Get-IPConfig 1.0.5 depcheck
	Switched to Update-VmTools 1.0.9
2.6.6 - 08/06/2012
	Switched to Get-OSVersion 1.1.0
	Switched to Test-Connections 1.0.7
2.6.7 - 08/13/2012
	Fixed missing output fields for failed systems.
2.6.8 - 08/24/2012
	Switched to Invoke-Patching 1.5.1
2.6.9 - 10/22/2012
	Switched to Reset-WindowsPatchingUI 1.0.3
2.7.0 - 11/27/2012
	Removed FileName Parameter
	Switched to Invoke-Patching 1.5.2
	Switched dependency test to Install-Patches 1.0.5 vbs
2.7.1 - 12/04/2012
	Switched to Test-Connection 1.0.8
	Changed logic for if all systems fail connection test it will reset the UI
2.7.2 - 12/13/2012
	Switched to Invoke-PSExec 1.0.9
	Switched to Invoke-Patching 1.5.3
2.7.3 - 12/14/2012
	Move all content from Invoke-Patching into parent script (This one) like all my other scripts
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
2.7.4 - 12/14/2012
	Removed all Vmware related items.  I've move these to my LBVmwareTools module.
	Switched to Test-Connections 1.0.9
2.7.5 - 12/17/2012
	Cleaned up regions
	Moved Check-Pending after checking hard drive space
	Changed so only writes local history log if there isn't enough hard drive space on remote system.
	Changed Disk Space check to check even if skipdrivespace switch is present to make sure there
		is a minimum space available on the remote client for the log and temp files.
2.7.6 - 12/18/2012
	Fixed some misspelling
	Added Reset UI before breaks/returns
	Reworked the Dependency check section.
2.7.7 - 12/26/2012
	Fixed some logic for reboots failing
	Added -NoReboot parameter switch and all the logic needed. So one round of patches can be
		installed without rebooting the system if there are not pending reboots at the start.
	Switched to Remove-Jobs 1.0.6
	Switched to Watch-Jobs 1.0.5
2.7.8 - 12/28/2012
	Removed Dot sourcing subscripts and load all when module is imported.
	Changed Show-ScriptStatus functions to not have second hypen in name.
	Changed Set-WinTitle functions to not have second hypen in name.
2.7.8 - 01/04/2013
	Removed -SubScript parameter from all subfunction calls.
	Removed dot sourcing subscripts because all are loaded when the module is imported now.
	Removed dependency check for subscripts.
	Added Import WindowsPatching Module to Background jobs.
	Removed Runas 32-bit from background jobs.
	Added Timezone argument passthrough to background jobs for logs.
2.7.9 - 01/09/2013
	Added Timezone to start and end times in results
2.8.0 - 01/14/2013
	Renamed WPM to WindowsPatching
2.8.1 - 01/18/2013
	Added WsusGroups, UpdateServer and WsusPort Parameters plus logic to handle it.
		This can eliminate the need of making text file lists and just patch a specific 
		WSUS group or groups.
	Renamed HostInputDesc to InputDesc
2.8.2 - 01/21/2013
	Added ExcludeComputers parameter and logic
	Renamed result to Choice in prompts
	Added Prompt to continue if not using -NoReboot switch (Dummy proofing)
	Fixed logic and conditioning for if WsusGroup is empty
	Added -NoReboot indicator to Logs
	Added Remote Log File Replacement if incorrectly Encoded
		A really old version of the script incorrectly encoded them as Unicode or UTF8
		and they need to ASCII. I thought that were all fixed, but ran into a few still
		incorrectly encoded.  This of course stops the information from being wrote to
		because I'm forcing ASCII encoding.
2.8.2 - 01/22/2013
	Tons of region cleanup and additions to better clarify flow
		Mostly so I could figure out the best placement for the Failed patches logic.
	Added Failed Patches condition processing from Latest Log
	Added logic to reboot once and try again if patches fail. Then bail if they fail a second time.
		This should help eliminate systems going into TimeOut or simply wasting time
		trying to install failed patches over and over until loop count limit is hit.
	Added string manipulation to pull the KB article numbers for the failed patches and add to the
		ScriptErrors output in results.
	Added Failed Patches to results
2.8.2 - 01/23/2013
	Renamed WsusPort to UpdateServerPort
	Added UpdateServerPort default grab from Module Defaults if missing
	Added ExcludeComputers parameter.
#>

#endregion Notes
