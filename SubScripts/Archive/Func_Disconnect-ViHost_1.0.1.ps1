#requires –version 2.0

Function Disconnect-VIHost {
	# Variables
	[boolean]$vidis = $false
	$checksnap = $null
	[boolean]$snapremoved = $false
	[string]$Notes = ''
	[boolean]$Success = $false
	
	If ($global:DisconnectVIHost) {
			Remove-Variable DisconnectVIHost -Scope "Global"
	}
	# Check if currently connected to a VIServer and Disconnect if so
	If ($global:DefaultVIServer -ne $null) {
		# DISCONNECT FROM vCENTER SERVER
		Disconnect-VIServer -Confirm:$false -Force:$true -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
		[boolean]$vidis = $true
		[string]$Notes += 'Disconnected '
	}
	Elseif ($global:DefaultVIServer -eq $null) {
		[boolean]$vidis = $true
		[string]$Notes += 'Not Connected '
	}
	Else {
		[string]$Notes += 'ViHost Connection Status Error '
	}
	
	$checksnap = Get-PSSnapin | select -ExpandProperty Name | Where-object {$_ -match "Vmware.VimAutomation.Core"}
	If ($checksnap -ne $null) {
		Remove-PSSnapin VMware.VimAutomation.Core -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Out-Null
		[boolean]$snapremoved = $true
		[string]$Notes += 'Snapin Removed '
	}
	Else {
		[boolean]$snapremoved = $true
		[string]$Notes += 'Snapin Already Removed '
	}
	# Check if successful
	If (($vidis -eq $true) -and ($snapremoved -eq $true)) {
		[boolean]$Success = $true
	}
	
	# Create Results Custom PS Object
	$global:DisconnectVIHost = New-Object -TypeName PSObject -Property @{
		VIDisconnected = $vidis
		Notes = $Notes
		Success = $Success
	}
}

#region Notes

<# Description
	PURPOSE:	Disconnect from vCenter or ViHost.	
	AUTHOR:		Levon Becker
#>

<# Dependents
	Func_Run-Patching
	Func_Get-VmTools
	Func_Get-VmHardware
	Func_Update-VmTools
	Func_Upgrade-Vmhareware
	Func_Get-OSVersion
	Func_Get-VMHostInfo
	Func_Get-VMGuestInfo
	Copy-ResourcePool
#>

<# Dependencies
	None
#>

<# Change Log
	1.0.0 - 04/29/2011 (Stable)
		Created
#>

<# To Do List

#>

<# Sources

#>

#endregion Notes
