#requires –version 2.0

Function Get-Runtime {
	Param (
		[parameter(Position=0,Mandatory=$true)][datetime]$StartTime
	)
	
	# Clear old psobject if present
	If ($global:GetRuntime) {
		Remove-Variable GetRuntime -Scope Global
	}
	
	[string]$Notes = ''
	[boolean]$Success = $false
	
	$Endtime = $null
	$EndtimeF = $null
	$timespan = $null
	$mins = $null
	$hrs = $null
	$sec = $null
	
	[datetime]$Endtime = Get-Date
	[string]$EndtimeF = Get-Date -Format g
	[TimeSpan]$timespan = New-TimeSpan -Start $StartTime -End $Endtime
	[int]$mins = ($timespan).Minutes
	[int]$hrs = ($timespan).Hours
	[int]$sec = ($timespan).Seconds
	[string]$Runtime = [String]::Format("{0:00}:{1:00}:{2:00}", $hrs, $mins, $sec)
	
	If ($Runtime) {
		[boolean]$Success = $true
		[string]$Notes = 'Completed'
	}
	
	# Create Results PSObject
	$global:GetRuntime = New-Object -TypeName PSObject -Property @{
		StartTime = $StartTime
		Endtime = $Endtime
		EndtimeF = $EndtimeF
		Runtime = $Runtime
		Success = $Success
		Notes = $Notes
	}
}

#$name = Get-WmiObject Win32_NetworkLoginProfile -ComputerName $ComputerName -ErrorAction SilentlyContinue |
#    Sort -Descending LastLogon |
#    Select * -First 1 |
#    ? {$_.LastLogon -match "(\d{14})"} |
#        ForEach-Object {
#            New-Object PSObject -Property @{
#                Name=$_.Name ;
#                LastLogon=[datetime]::ParseExact($matches[0], "yyyyMMddHHmmss", $null)
#            }

#region Notes

<# Description
	Function to calculate script Runtime based on starttime input variable.
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Add-NFSDS
	ConvertTo-ASCII
	Add-NFSMountToESXHost
	Get-DiskSpace
	Get-PendingPatches
	Get-PendingReboot
	Get-Vmhardware
	Get-Vmtools
	Get-HostDomain
	Get-HostIP
	Get-IPconfig
	Get-NBUVersion
	Get-OSVersion
	Get-RegValue
	Get-TimeZone
	Get-VMGuestInfo
	Get-VMHostInfo
	Watch-Jobs
	Restart-Host
	Install-Patches
	Invoke-PSExec
	Invoke-PSService
	Set-Header
	Test-Connections
	Test-Permissions
	Get-HostIP
	Get-IntIPfromExtIP
	Get-PendingUpdates
	IIS-Security
	Template_Jobloop
	Test-Permissions
	Test-WSUSClient
#>

<# Dependencies
None
#>

<# Change Log
1.0.0 - 04/04/2011 (Beta)
	Created
1.0.1 - 04/29/2011 (Stable)
	Changed a lot, psobject output
	Added Endtimef 
	Renamed Starttimeformatted to StartTimef
	Changed Runtime format to 00:00:00
1.0.2 - 04/18/2012
	Changed version scheme
	Moved Info section to end.
1.0.3 - 05/02/2012
	Renamed to Get-Runtime instead of Calc-Runtime
	Some more variable and parameter renames to fit the my latest standards
#>

<# To Do List
1. Find way to format Get-Date manually to be like -format g to eliminate the need for StartTimef and Endtimef
#>

<# Sources
#>

#endregion Notes
