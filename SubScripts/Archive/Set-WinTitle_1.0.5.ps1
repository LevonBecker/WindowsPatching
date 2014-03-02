#requires –version 2.0

Function Set-WinTitle-Start {
	Param (
		[parameter(Mandatory=$true)][string]$title
	)
#	Clear
	$Host.UI.RawUI.WindowTitle = $title
}

Function Set-WinTitle-Base {
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
			$vmwareregpath = 'hklm:\SOFTWARE\Wow6432Node\VMware, Inc.'
		}
		Else {
			$vmwareregpath = 'hklm:\SOFTWARE\VMware, Inc.'
		}
		$pcliregpath = $vmwareregpath + '\VMware vSphere PowerCLI'
		$pcliver = ((Get-ItemProperty -Path $pcliregpath -name InstalledVersion).InstalledVersion).Substring(0,3)
		
		$global:wintitle_base = "Powershell v$PSVersion - CLR v$CLRVersion - PowerCLI v$pcliver - Script v$ScriptVersion"
		$Host.UI.RawUI.WindowTitle = $global:wintitle_base
	}
	Else {
		$global:wintitle_base = "Powershell v$PSVersion - CLR v$CLRVersion - Script v$ScriptVersion"
		$Host.UI.RawUI.WindowTitle = $global:wintitle_base
	}
}

Function Set-WinTitle-Input {
	Param (
		[parameter(Mandatory=$true)][string]$wintitle_base,
		[parameter(Mandatory=$true)][string]$InputItem
	)
#	If ($hostmethod -eq 'computer') {
#		$i = "$computer"
#	}
#	ElseIf ($hostmethod -eq 'file') {
#		$i = "$fileList"
#	}
#	Else {
#		$i = 'ERROR'
#	}
	$global:wintitle_input = $wintitle_base + " - ($InputItem)"
	$Host.UI.RawUI.WindowTitle = $global:wintitle_input
}

Function Set-WinTitle-FileList-Testcount {
	Param (
		[parameter(Mandatory=$true)][string]$wintitle_base,
		[parameter(Mandatory=$true)][string]$rootfile,
		[parameter(Mandatory=$true)][string]$fileList,
		[parameter(Mandatory=$true)][string]$ComputerName,
		[parameter(Mandatory=$true)][int]$testcount
	)
	$wintitle_test = $wintitle_base + " ($rootfile\$fileList\$ComputerName) - Tests Left ($testcount)"
	$Host.UI.RawUI.WindowTitle = $wintitle_test
}

Function Set-WinTitle-Hostfile-Testcount {
	Param (
		[parameter(Mandatory=$true)][string]$wintitle_base,
		[parameter(Mandatory=$true)][string]$hostfile,
		[parameter(Mandatory=$true)][string]$ComputerName,
		[parameter(Mandatory=$true)][int]$testcount
	)
	$wintitle_testcount = $wintitle_base + " ($hostfile) - Tests Left ($testcount)"
	$Host.UI.RawUI.WindowTitle = $wintitle_testcount
}

Function Set-WinTitle-JobCount {
	Param (
		[parameter(Mandatory=$true)][string]$wintitle_input,
		[parameter(Mandatory=$true)][int]$jobcount
	)
	$wintitle_jobs = $wintitle_input + " - Jobs Running ($jobcount)"
	$Host.UI.RawUI.WindowTitle = $wintitle_jobs
}

Function Set-WinTitle-JobTimeout {
	Param (
		[parameter(Mandatory=$true)][string]$wintitle_input
	)
	$wintitle_jobtimeout = $wintitle_input + ' - (JOB TIMEOUT)'
	$Host.UI.RawUI.WindowTitle = $wintitle_jobtimeout
}

Function Set-WinTitle-Completed {
	Param (
		[parameter(Mandatory=$true)][string]$wintitle_input
	)
	$wintitle_completed = $wintitle_input + ' - (COMPLETED)'
	$Host.UI.RawUI.WindowTitle = $wintitle_completed
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
	Func_Run-Patching
	Test-Permissions
	Watch-Jobs
	Test-WSUSClient
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
		Added $CLRVersion parameter to Set-WinTitle-Base
#>

<# To Do List
#>

<# Sources
#>

#endregion Notes
