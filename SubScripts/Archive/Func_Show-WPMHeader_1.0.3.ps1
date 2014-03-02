﻿#requires –version 2.0

Function Show-WPMHeader {
	Param (
		[parameter(Mandatory=$true)][string]$SubScripts,
		[parameter(Mandatory=$false)][switch]$NoTips
	)

	If ((Get-Command -Name "Show-WPMTip" -ErrorAction SilentlyContinue) -eq $null){
		. "$SubScripts\Func_Show-WPMTip_1.0.1.ps1"
	}

#	# Standard Console Header
#	Write-Host 'Windows PowerShell'
#	Write-Host 'Copyright (C) 2009 Microsoft Corporation. All rights reserved.'
#	Write-Host ''

	# GET PS AND CLR VERSIONS FOR HEADER
	$PSVersion = $PSVersionTable.PSVersion.ToString()
	$CLRVersion = ($PSVersionTable.CLRVersion.ToString()).Substring(0,3)
	$WPMModuleManifest = Test-ModuleManifest -Path "$Global:WindowsPatchingModulePath\WindowsPatching.psd1"
	[string]$WPMModuleVersion = $WPMModuleManifest.Version.ToString()

	# SHOW CONSOLE HEADER
	Clear
	Write-Host "PowerShell v$PSVersion | CLR v$CLRVersion | Windows Patching Module v$WPMModuleVersion"
	Write-Host '------------------------------------------------------------'
	Write-Host -nonewline "Run This 1st to Set Defaults:`t"
	Write-Host -fore Yellow "Set-WindowsPatchingDefaults"
	Write-Host -nonewline "Check WSUS Registry Settings:`t"
	Write-Host -fore Yellow "Test-WSUSClient"
	Write-Host -nonewline "Host List of WSUS Clients:`t"
	Write-Host -fore Yellow "Get-WSUSClients"
	Write-Host -nonewline "Host List of Failed Patches:`t"
	Write-Host -fore Yellow "Get-WSUSFailedClients"
	Write-Host -nonewline "List Of Pending Patches:`t"
	Write-Host -fore Yellow "Get-PendingUpdates"
	Write-Host -nonewline "Apply WSUS Approved Patches:`t"
	Write-Host -fore Yellow "Install-Patches"
	#Write-Host "`n"
	Write-Host ''

	If (($NoTips.IsPresent) -eq $false) {
		Show-WPMTip
	}

}

#region Notes

<# Description
	Clear the screen and show WindowsPatching Module information at the top.
	Plus show WindowsPatching Tips underneath the header.
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	WindowsPatching.psm1
	Func_Reset-WPMUI
#>

<# Dependencies
#>

<# To Do List
	
#>

<# Change Log
	1.0.0 - 05/03/2012
		Created
	1.0.1 - 05/10/2012
		Added parameters to have this Function run Tips
		Added switch to not show Tips
		Added conditional function loading
	1.0.2 - 05/14/2012
		Added Get-PendingUpdates
	1.0.3 - 10/22/2012
		Added Get-FailedClients
#>

#endregion Notes