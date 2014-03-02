#requires –version 2.0

Function Set-WinTitleStart {
	Param (
		[parameter(Mandatory=$true)][string]$Title
	)
#	Clear
	$Host.UI.RawUI.WindowTitle = $Title
}

Function Set-WinTitleBase {
	Param (
		[parameter(Mandatory=$true)][string]$ScriptVersion,
		[parameter(Mandatory=$false)][switch]$IncludePowerCLI
	)
	$PSVersion = $PSVersionTable.PSVersion.ToString()
	$CLRVersion = ($PSVersionTable.CLRVersion.ToString()).Substring(0,3)
	
	If ($IncludePowerCLI.IsPresent -eq $true) {
		If (((Get-WmiObject win32_operatingSystem -ComputerName localhost).OSArchitecture) -eq '64-bit') {
			$ScriptHostArch = '64'
		}
		Else {
		$ScriptHostArch = '32'
		}
		If ($ScriptHostArch -eq '64') {
			$VmwareRegPath = 'hklm:\SOFTWARE\Wow6432Node\VMware, Inc.'
		}
		Else {
			$VmwareRegPath = 'hklm:\SOFTWARE\VMware, Inc.'
		}
		$PowerCLIRegPath = $VmwareRegPath + '\VMware vSphere PowerCLI'
		$PowerCLIVersion = ((Get-ItemProperty -Path $PowerCLIRegPath -name InstalledVersion).InstalledVersion).Substring(0,3)
		
		$Global:WinTitleBase = "Powershell v$PSVersion - CLR v$CLRVersion - PowerCLI v$PowerCLIVersion - Script v$ScriptVersion"
		$Host.UI.RawUI.WindowTitle = $Global:WinTitleBase
	}
	Else {
		$Global:WinTitleBase = "Powershell v$PSVersion - CLR v$CLRVersion - Script v$ScriptVersion"
		$Host.UI.RawUI.WindowTitle = $Global:WinTitleBase
	}
}

Function Set-WinTitleInput {
	Param (
		[parameter(Mandatory=$true)][string]$WinTitleBase,
		[parameter(Mandatory=$true)][string]$InputItem
	)
	$Global:WinTitleInput = $WinTitleBase + " - ($InputItem)"
	$Host.UI.RawUI.WindowTitle = $Global:WinTitleInput
}

Function Set-WinTitleJobCount {
	Param (
		[parameter(Mandatory=$true)][string]$WinTitleInput,
		[parameter(Mandatory=$true)][int]$JobCount
	)
	$WinTitleJobs = $WinTitleInput + " - Jobs Running ($JobCount)"
	$Host.UI.RawUI.WindowTitle = $WinTitleJobs
}

Function Set-WinTitleJobTimeout {
	Param (
		[parameter(Mandatory=$true)][string]$WinTitleInput
	)
	$WinTitleJobTimeOut = $WinTitleInput + ' - (JOB TIMEOUT)'
	$Host.UI.RawUI.WindowTitle = $WinTitleJobTimeOut
}

Function Set-WinTitleCompleted {
	Param (
		[parameter(Mandatory=$true)][string]$WinTitleInput
	)
	$WinTitleCompleted = $WinTitleInput + ' - (COMPLETED)'
	$Host.UI.RawUI.WindowTitle = $WinTitleCompleted
}

#region Notes

<# Description
	Multiple Functions for changing the Powershell console Window Title
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Install-Patches
	Test-Permissions
	Watch-Jobs
	Test-WSUSClient
	Get-PendingUpdates
	Get-WSUSClients
	Get-WSUSFailedClients
	Move-WSUSClientToGroup
#>

<# Dependencies
#>

<# Change Log
1.0.0 - 02/17/2011 (Beta)
	Created
1.0.1 - 04/11/2011 (Stable)
	Cleaning up to work independant
1.0.2 - 05/13/2011
	Changed $file to $fileList
1.0.3 - 02/07/2011
	Changed $psver to $PSVersion
	Added $CLRVersion parameter to Set-WinTitleBase
1.0.6 - 01/04/2013
	Changed function names to only have one hyphen.
	Removed Set-WinTitleHostfileTestcount and Set-WinTitleFileListTestcount
	Remove Underscores from parameters and variable names.
#>

<# To Do List
#>

<# Sources
#>

#endregion Notes
