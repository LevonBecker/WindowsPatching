#requires –version 2.0

Function Get-DiskSpace {
	Param (
		[parameter(Position=0,Mandatory=$true)][string]$ComputerName,
		[parameter(Mandatory=$false)][int]$MinFreeMB = '500'
	)
	# CLEAR VARIBLES
	[string]$Notes = ''
	[boolean]$Success = $false
	[datetime]$SubStartTime = Get-Date
	[string]$ComputerName = $ComputerName.ToUpper()

	[boolean]$wmiconnected = $false
	[boolean]$passed = $false
	[string]$hdid = 'Unknown'
	
	If ($global:GetDiskSpace) {
		Remove-Variable GetDiskSpace -Scope "Global"
	}
	
	Try {
		[array]$logicaldisk = Get-WmiObject -ComputerName $ComputerName Win32_LogicalDisk -ErrorAction Stop
		[boolean]$wmiconnected = $true
	}
	Catch {
		[string]$Notes += 'WMI Query Failed '
		[boolean]$wmiconnected = $false
	}
	
	If ($wmiconnected -eq $true) {
		[Management.ManagementObject]$sysdrive = $logicaldisk | Where-Object {$_.DeviceID -eq 'C:'}
		[int]$mbfree = "{0:N0}" -f ($sysdrive.FreeSpace / 1MB) 
		[string]$hdid = ($sysdrive).DeviceID
		[int]$drivesize = "{0:N0}" -f ($sysdrive.Size / 1MB)  
		If ($mbfree) {
			If ($mbfree -ge $MinFreeMB) {
				[boolean]$passed = $true
				[string]$Notes += 'Greater than or equal to Minimum Space on disk '
			}
			Else {
				[string]$Notes += 'Less than Minimum Space on disk '
			}
		[boolean]$Success = $true
		}
		Else {
			[string]$Notes += 'Error: Evaluating System Drive Space '
		}
	}
	Get-Runtime -StartTime $SubStartTime
	
	# Create Results Custom PS Object
	$global:GetDiskSpace = New-Object -TypeName PSObject -Property @{
		ComputerName = $ComputerName
		Success = $Success
		Notes = $Notes
		WMIConnected = $wmiconnected
		Drive = $hdid
		DriveSize = $drivesize
		MinFreeMB = $MinFreeMB
		FreeSpaceMB = $mbfree
		Passed = $passed
		Starttime = $SubStartTime
		Endtime = $global:GetRunTime.Endtime
		Runtime = $global:GetRunTime.Runtime
	}
}

#region Notes

<# Description
	Function to check hard disk space on remote ComputerName for minimum amount.
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Install-Patches
	Get-HostInfo
#>

<# Dependencies
	Get-Runtime
#>

<# Change Log
1.0.0 - 02/15/2011 (Beta)
	Created
1.0.1 - 05/05/2011
	Converted results to PSObject output.
	Set default on minfree varible instead of condition statement doing it.
	Set parameter and other variable to specific case
	Added better error handling with Try/Catch, spliting up commands and conditions
	Added Runtime info
1.0.2 - 07/21/2011
	Changed $passed = 'Unknown' to $passed = $false default value to fix it so when 
	there is not enough space it we have False as the value as intended.
1.0.3 - 01/04/2013
	Removed -SubScript parameter from all subfunction calls.
	Removed dot sourcing subscripts because all are loaded when the module is imported now.
#>

<# To Do List
#>

<# Sources
#>

#endregion Notes
