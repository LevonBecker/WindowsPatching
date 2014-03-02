#requires –version 2.0

Function Get-PendingReboot {
	Param (
		[parameter(Position=0,Mandatory=$true)][string]$ComputerName,
		[parameter(Mandatory=$true)][string]$Assets
	)
	# CLEAR VARIABLES
	[string]$Notes = ''
	[boolean]$Success = $false
	[datetime]$SubStartTime = Get-Date
	[string]$ComputerName = $ComputerName.ToUpper()
	
	[boolean]$Pending = $false
	[int]$failedcount = 0
	
	[int]$reboot_attempts_count = 0
	$ComputerName_active = $null
	$ComputerName_new = $null
	
	If ($global:GetPendingReboot) {
			Remove-Variable GetPendingReboot -Scope "Global"
	}

	## SET REGISTRY VARIABLES ##
	# HIVE
	[string]$HKey = 'LocalMachine'
	# SubKey ROOTS
	[string]$SubKey_ServerManager = 'SOFTWARE\Microsoft\ServerManager'
	[string]$SubKey_Control = 'SYSTEM\CurrentControlSet\Control'
	# SubKey SUBROOTS
	[string]$SubKey_SessionManager = Join-Path $SubKey_Control 'Session Manager'
	[string]$SubKey_ComputerName = Join-Path $SubKey_Control 'ComputerName'
	# SubKey TAILS
	[string]$SubKey_ActiveComputerName = Join-Path $SubKey_ComputerName 'ActiveComputerName'
	[string]$SubKey_ComputerName2 = Join-Path $SubKey_ComputerName 'ComputerName'
	# SubKey Auto Update Reboot Required
	[string]$SubKey_AutoUpdate = 'SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update'
	[string]$SubKey_AutoUpdate_RebootRequired = 'RebootRequired'
	# SubKey Installed Component Based Servicing Features awaiting reboot "After installing Features" (2008+ ONLY)
	[string]$SubKey_CBS = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing'
	[string]$SubKey_CBS_RebootPending = 'RebootPending'
	
	# StringS
	[string]$String_Pending_FileRename = 'PendingFileRenameOperations'
	[string]$String_Pending_FileRename2 = 'PendingFileRenameOperations2'
	[string]$String_Reboot_Attempts = 'CurrentRebootAttempts'
	[string]$String_ComputerName = 'ComputerName'
	# HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired
	
	# Check Registry for Windows Update RebootRequired SubKey
	# HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired
	Get-RegValue -ComputerName $ComputerName -Assets $Assets -HKey $HKey -SubKey $SubKey_AutoUpdate
	If ($global:GetRegValue.Success -eq $true) {
		[array]$wua_SubKeyList = $global:GetRegValue.RegSubKeyList
	}
	Else {
		[string]$Notes +='WUA RebootRequired Check Failed - ' + ($global:GetRegValue.Notes) + ' - '
		$failedcount++
	}
	If ($wua_SubKeyList -contains $SubKey_AutoUpdate_RebootRequired) {
		[boolean]$Pending = $true
		[string]$Notes += 'Pending Reboot for Windows Update - '
	}

	
	# Check Registry for Windows Update RebootRequired SubKey (2008+ only)
	# HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired
	Get-RegValue -ComputerName $ComputerName -Assets $Assets -HKey $HKey -SubKey $SubKey_CBS
	If ($global:GetRegValue.Success -eq $true) {
		[array]$cbs_SubKeyList = $global:GetRegValue.RegSubKeyList
	}
#	Else {
#		[string]$Notes +='May not be 2008 ComputerName '
#		[string]$Notes += ' - '
#		$failedcount++
#	}
	If ($cbs_SubKeyList -contains $SubKey_CBS_RebootPending) {
		[boolean]$Pending = $true
		[string]$Notes += 'Pending Reboot for Installed Features - '
	}
	
	# CHECK REGISTRY VALUE (CHECK PENDING FILE RENAME OPERATIONS)
	# HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations
	Get-RegValue -ComputerName $ComputerName -Assets $Assets -HKey $HKey -SubKey $SubKey_SessionManager
	If ($global:GetRegValue.Success -eq $true) {
		[array]$sessionmanager_regvaluenames = $global:GetRegValue.RegValueNames
	}
	Else {
		[string]$Notes +='Pending File Rename Check Failed - ' + ($global:GetRegValue.Notes) + ' - '
		$failedcount++
	}
	If ($sessionmanager_regvaluenames -contains $String_Pending_FileRename) {
		[boolean]$Pending = $true
		[string]$Notes += 'Pending File Rename 1 - '
	}
	If ($sessionmanager_regvaluenames -contains $String_Pending_FileRename2) {
		[boolean]$Pending = $true
		[string]$Notes += 'Pending File Rename 2 - '
	}
	
	# CHECK REGISTRY VALUE (CURRENT REBOOT ATTEMPTS) [ONLY Windows 2008+]
	# HKLM:\SOFTWARE\Microsoft\ServerManager\CurrentRebootAttempts
	Get-RegValue -ComputerName $ComputerName -Assets $Assets -HKey $HKey -SubKey $SubKey_ServerManager -String $String_Reboot_Attempts
	[string]$reboot_attempts_count = $global:GetRegValue.RegStringValue
	If ($reboot_attempts_count -gt 0) {
		[boolean]$Pending = $true
		[string]$Notes += 'Attempted Reboots - '
	}

	# CHECK REGISTRY VALUE (COMPUTER NAME CHANGE PENDING)
	# HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName\ComputerName (old/current)
	# HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName\ComputerName (new)
	Get-RegValue -ComputerName $ComputerName -Assets $Assets -HKey $HKey -SubKey $SubKey_ActiveComputerName -String $String_ComputerName
	If ($global:GetRegValue.Success -eq $true) {
		[string]$ComputerName_active = $global:GetRegValue.RegStringValue
	}
	Else {
		[string]$Notes +='Active Computer Name Check Failed - ' + ($global:GetRegValue.Notes) + ' - '
		$failedcount++
	}
	Get-RegValue -ComputerName $ComputerName -Assets $Assets -HKey $HKey -SubKey $SubKey_ComputerName2 -String $String_ComputerName
	If ($global:GetRegValue.Success -eq $true) {
		[string]$ComputerName_new = $global:GetRegValue.RegStringValue
	}
	Else {
		[string]$Notes +='New Computer Name Check Failed - ' + ($global:GetRegValue.Notes) + ' - '
		$failedcount++
	}
	If ($ComputerName_active -ne $ComputerName_new) {
		[boolean]$Pending = $true
		[string]$Notes += 'Pending Host Rename - '
	}
	
	# Determine Results
	If ($failedcount -eq 0) {
		[boolean]$Success = $true
		If ($Pending -eq $false) {
			[string]$Notes += 'No Pending Reboot '
		}
	}
	Else {
		[string]$Pending = 'Unknown'
	}
	
	Get-Runtime -StartTime $SubStartTime
	
	# Create Results Custom PS Object
	$global:GetPendingReboot = New-Object -TypeName PSObject -Property @{
		ComputerName = $ComputerName
		Notes = $Notes
		Success = $Success
		Pending = $Pending
		Starttime = $SubStartTime
		Endtime = $global:GetRunTime.Endtime
		Runtime = $global:GetRunTime.Runtime
	}
} # End Function

#region Notes

<# Description
	Audit remote computer for Pending Reboot in Registry.	
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
	Get-RegValue
#>

<# Change Log
1.0.0 - 02/14/2011 (Beta)
	Created
1.0.1 - 05/06/2011 (WIP)
	Converted results to PSObject output.
	Added Runtime info
1.0.2 - 05/08/2011 (Stable)
	Utilized Get-RegValue sub script
	Finished newer logic implementation
1.0.3 - 06/27/2011 (Stable)
	Cleaned up old code before I created Get-RegValue subfunction
1.0.4 - 11/07/2011
	Added Windows Update Reboot Required SubKey check
1.0.5 - 04/20/2012
	Changed Computer to ComputerName
1.0.7 - 01/04/2013
	Removed -SubScript parameter from all subfunction calls.
	Removed dot sourcing subscripts because all are loaded when the module is imported now.
#>

#endregion Notes
