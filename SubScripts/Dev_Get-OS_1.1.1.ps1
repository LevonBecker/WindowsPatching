#requires –version 2.0

Function Get-OS {
	Param (
		[parameter(Position=0,Mandatory=$true)][string]$ComputerName,
		[parameter(Mandatory=$false)][switch]$StayConnected,
		[parameter(Mandatory=$false)][string]$vCenter,
		[parameter(Mandatory=$false)][boolean]$UseAltViCredsBool = $false,
		[parameter(Mandatory=$false)]$ViCreds,
		[parameter(Mandatory=$false)][switch]$SkipVimQuery
	)
	# VARIABLES
	[string]$Notes = ''
	[boolean]$Success = $false
	[datetime]$SubStartTime = Get-Date
	[string]$ComputerName = $ComputerName.ToUpper()

	$WMIOperatingSystem = $null
	$WMIPageFileSettings = $null
	[boolean]$WMIConnected = $false
	[boolean]$vimquerysuccess = $false
	
	If ($Global:GetOS) {
		Remove-Variable GetOS -Scope "Global" | Out-Null
	}
	
	#region WMI Queries
	
		Try {
			$WMIOperatingSystem = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName -ErrorAction Stop
			$WMIPageFileSettings = Get-WmiObject -Class Win32_PageFileSetting -ComputerName $ComputerName -ErrorAction Stop
			[boolean]$WMIConnected = $true
		}
		Catch {
			[string]$Notes += 'WMI Query Failed  '
			[boolean]$WMIConnected = $false
		}
		If ($WMIConnected -eq $true) {
		
			#region OS Version
			
				$OSVersion = $WMIOperatingSystem.Caption
				If (($OSVersion | Select-String -Pattern ',') -ne $null) {
					# Remove any commas in the OS Version
					[string]$OSVersion = $OSVersion.Replace(',', '')
				}
				If (($OSVersion | Select-String -Pattern '®') -ne $null) {
					# Remove any commas in the OS Version
					[string]$OSVersion = $OSVersion.Replace('®', '')
				}
				If (($OSVersion | Select-String -Pattern '(R)') -ne $null) {
					# Remove Registered Trademark
					[string]$OSVersion = $OSVersion.Replace('(R)', '') 
				}
			
				$OSServicePack = $WMIOperatingSystem.CSDVersion
				If ($OSServicePack -eq $null) {
					[string]$OSServicePack = 'Service Pack 0'
				}
				# OSArchitecture OperatingSystem property only available for Vista/2008 or higher.
				[string]$OSArchitecture = $WMIOperatingSystem.OSArchitecture
				If (!$OSArchitecture) {
					$WMIProcessor = $null
					$WMIProcessor = Get-WmiObject -Class Win32_Processor -ComputerName $ComputerName
					[int]$AddressWidth = $WMIProcessor | Select-Object -ExpandProperty AddressWidth -First 1
					If ($AddressWidth -eq '32') {
						[string]$OSArchitecture = '32-bit'
					}
					ElseIf ($AddressWidth -eq '64') {
						[string]$OSArchitecture = '64-bit'
					}
				}
				[string]$OSOther = $WMIOperatingSystem.OtherTypeDescription
				[string]$OSDescription = $WMIOperatingSystem.Description
				[string]$WindowsDirectory = $WMIOperatingSystem.WindowsDirectory
			
			#endregion OS Version
			
			#region Uptime
			
				[datetime]$LastBootUpTime = [Management.ManagementDateTimeConverter]::ToDateTime($WMIOperatingSystem.LastBootUpTime)
				[datetime]$LocalDateTime = [Management.ManagementDateTimeConverter]::ToDateTime($WMIOperatingSystem.LocalDateTime)
				[timespan]$UptimeTimeSpan = $LocalDateTime - $LastBootUpTime
				[int]$Days = $UptimeTimeSpan.Days
				[int]$Hours = $UptimeTimeSpan.Hours
				[int]$Minutes = $UptimeTimeSpan.Minutes
				[string]$Uptime = [String]::Format("{0:00}:{1:00}:{2:00}", $Days, $Hours, $Minutes)
				
			#endregion Uptime
			
			#region Memory
			
				[int]$FreeVirtualMemoryMB = ($WMIOperatingSystem.FreeVirtualMemory / 1KB)
				[int]$FreePhysicalMemoryMB = ($WMIOperatingSystem.FreePhysicalMemory / 1KB)
			
			#endregion Memory
			
			#region PageFile
			
				$PageFiles = $null
				Foreach ($PageFile in $WMIPageFileSettings) {
					[string]$PageFiles += 'Path: (' + $PageFile.Name + ') InitialSize: (' + $PageFile.InitialSize + ' MB)' + ' MaximumSize: (' + $PageFile.MaximumSize + ' MB)' + '  '
				}
			
			#endregion PageFile
			
			[boolean]$Success = $true
			[string]$LookupMethod = 'WMI'
		}
	
	#endregion WMI Queries
	
	#region vCenter Queries
	
		# If WMI Fails Try vCenter Query
		If (($WMIConnected -eq $false) -and ($SkipVimQuery.IsPresent -eq $false)) {
			If ($StayConnected.IsPresent -eq $true) {
				Get-VmGuestInfo -ComputerName $ComputerName -vCenter $vCenter -UseAltViCredsBool $UseAltViCredsBool -ViCreds $ViCreds -StayConnected -SubScripts $SubScripts
			}
			Else {
				Get-VmGuestInfo -ComputerName $ComputerName -vCenter $vCenter -UseAltViCredsBool $UseAltViCredsBool -ViCreds $ViCreds -SubScripts $SubScripts
			}
			If ($Global:GetVmGuestInfo.Success -eq $true) {
				[string]$OSVersion = $Global:GetVmGuestInfo.OSVersion
				[boolean]$vimquerysuccess = $true
				[string]$LookupMethod = 'VIM'
				[boolean]$Success = $true
			}
			Else {
				[boolean]$vimquerysuccess = $false
				[string]$Notes += 'VIM Query Failed  '
			}

		} #/If WMI Query failed try vCenter
	
	#endregion vCenter Queries
	
	#region OSVersionShortName and OSArch
	
		If ($Success -eq $true) {
			If ($OSVersion -like "*2008 R2*") {
				[string]$OSVersionShortName = '2008R2'
			}
			Elseif ($OSVersion -like "*2008*") {
				[string]$OSVersionShortName = '2008'
			}
			Elseif ($OSVersion -like "*2012*") {
				[string]$OSVersionShortName = '2012'
			}
			Elseif ($OSVersion -like "*7*") {
				[string]$OSVersionShortName = '7'
			}
			Elseif ($OSVersion -like "*Windows 8*") {
				[string]$OSVersionShortName = '8'
			}
			Elseif ($OSVersion -like "*Vista*") {
				[string]$OSVersionShortName = 'Vista'
			}
			Elseif ($OSVersion -like "*2003*") {
				[string]$OSVersionShortName = '2003'
			}
			Elseif ($OSVersion -like "*2000*") {
				[string]$OSVersionShortName = '2000'
			}
			Elseif ($OSVersion -like "*XP*") {
				[string]$OSVersionShortName = 'XP'
			}
			Elseif ($OSVersion -like "*Windows NT*") {
				[string]$OSVersionShortName = 'NT'
			}
			Else {
				[string]$OSVersionShortName = 'Other'
			}
		}
		Else {
			$OSVersionShortName = 'Unknown'
		}
		
#		If (($OSVersionShortName -eq '2000') -or ($OSVersionShortName -eq 'NT')) {
#			[string]$OSArchitecture = '32-bit'
#		}
#		ElseIf (($OSArchitecture -eq $null) -or ($OSArchitecture -eq '')) {
#			# If x64 is in the OS Version String
#			If (($OSVersion | Select-String -Pattern 'x64') -ne $null) {
#				[string]$OSArchitecture = '64-bit'
#			}
#			# If 32-bit is in the OS Version String
#			ElseIf (($OSVersion | Select-String -Pattern '32-bit') -ne $null) {
#				[string]$OSArchitecture = '32-bit'
#			}
#			Else {
#				[string]$OSArchitecture = '32-bit'
#			}
#		}
	
	#endregion OSVersionShortName and OSArch
		
	#region 
	If (!$OSArchitecture) {
		[string]$OSArchitecture = 'Unknown'
	}
	If (!$OSVersion) {
		[string]$OSVersion = 'Unknown'
	}
	If (!$OSServicePack) {
		[string]$OSServicePack = 'Unknown'
	}
	If (!$OSVersionShortName) {
		[string]$OSVersionShortName = 'Unknown'
	}
	If (!$OSDescription) {
		[string]$OSDescription = 'Unknown'
	}
	If (!$WindowsDirectory) {
		[string]$WindowsDirectory = 'Unknown'
	}
	If (!$OSOther) {
		[string]$OSOther = 'N/A'
	}
	If (!$LookupMethod) {
		[string]$LookupMethod = 'All Failed'
	}
	
	Get-Runtime -StartTime $SubStartTime
	
	# Create Results Custom PS Object
	$Global:GetOS = New-Object -TypeName PSObject -Property @{
		ComputerName = $ComputerName
		Success = $Success
		Notes = $Notes
		Starttime = $SubStartTime
		Endtime = $Global:GetRunTime.Endtime
		Runtime = $Global:GetRunTime.Runtime
		LookupMethod = $LookupMethod
		OSVersion = $OSVersion
		OSServicePack = $OSServicePack
		OSVersionShortName = $OSVersionShortName
		OSArchitecture = $OSArchitecture
		OSOther = $OSOther
		OSDescription = $OSDescription
		WindowsDirectory = $WindowsDirectory
		LastBootUpTime = $LastBootUpTime
		Uptime = $Uptime
		FreePhysicalMemoryMB = $FreePhysicalMemoryMB
		FreeVirtualMemoryMB = $FreeVirtualMemoryMB
		PageFiles = $PageFiles
	}
}

#region Notes

<# Description
	Query Windows OS Version Name on Remote System.
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Func_Get-IIS-Security
	Func_Invoke-Patching
	Test-MCAgents
	Test-WSUSClient
	Get-CurrentMCVersions
	Get-PendingUpdates
	Get-HostInfo
#>

<# Dependencies
	Func_Get-Runtime
	Func_Get-VmGuestInfo
#>

<# Change Log
	1.0.0 - 04/04/2011 (Beta)
		Created
	1.0.1 - 04/22/2011 (Stable)
		Cleaned up information sections
		Changed output to psobject
		Added Vmware vCenter OS lookup if WMI fails
		Added several Try/Catch Conditions for better error handling
	1.0.2 - 05/06/2011
		Added condition for the replace command in OS Caption/version
		Added Runtime calc piece
		Changed end psobject to use Hashtable for properties.
		Added ViHost connect/disconnect sub scripts
	1.0.3 - 10/11/2011
		Changed Output object to GetOS instead of getosver
	1.0.4 - 11/10/2011
		Added more parameter settings
		Added $UseAltViCreds and $ViCreds
	1.0.5 - 11/11/2011
		Changed to use Func_Get-VmGuestInfo_1.0.4.ps1
	1.0.6 - 11/19/2011
		Added OSType 2008R2, 7, Vista, and XP
		Added Windows Caption cleanup for ®
		Removed a few Notes about success
		Added $osother = 'N/A' (Didn't fix blank)
		Changed up the OSArch logic
	1.0.6 - 02/01/2012
		Removed Func_Dissconnect-VIHost
	1.0.8 - 05/01/2012
		Fixing it so SkipAllVmware works from Install-Patches / Invoke-Patching
		Change vCenter to not mandatory
		Changed the SkipVimQuery parameter to a switch
	1.1.0 - 05/31/2012
		Moved Get-VmGuestInfo to only load if needed.'
		Added Windows 8 and Server 2012 ShortNames
#>

<# To Do List

	1. Add and Active Directory Lookup for the OS version

#>

<# Sources

	Remove/Replace text in string
		http://technet.microsoft.com/en-us/library/ee692804.aspx
	
#>

#endregion Notes
