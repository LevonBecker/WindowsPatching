#requires –version 2.0

Function Get-HardwareInfo {
	Param (
		[parameter(Position=0,Mandatory=$true)][string]$ComputerName,
		[parameter(Mandatory=$true)][string]$vCenter,
		[parameter(Mandatory=$false)][string]$StayConnected = $false,
		[parameter(Mandatory=$false)][switch]$SkipVimQuery,
		[parameter(Mandatory=$true)][string]$SubScripts
	)
	# Variables
	[string]$Notes = ''
	[boolean]$Success = $false
	[datetime]$SubStartTime = Get-Date
	[string]$ComputerName = $ComputerName.ToUpper()
	
	$wmiquery = $null
	[string]$wmiconnect = $false
	[string]$model = 'Unknown'
	
	
	
	. "$SubScripts\Func_Connect-ViHost_1.0.7.ps1"
	. "$SubScripts\Func_Disconnect-ViHost_1.0.1.ps1"
	. "$SubScripts\Func_Get-Runtime_1.0.3.ps1"
#	. "$SubScripts\Func_Get-VmGuestInfo_1.0.5.ps1"
	
	If ($global:GetHardwareInfo) {
		Remove-Variable GetHardwareInfo -Scope "Global" | Out-Null
	}
	
	If ($ComputerName) {
		# WMI Query
		Try {
			$wmiquery = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $ComputerName -ErrorAction Stop
			[boolean]$wmiconnect = $true
		}
		Catch {
			$Notes += 'WMI Query Failed - '
			[boolean]$wmiconnect = $false
		}
		If ($wmiconnect -eq $true) {
			[string]$model = $wmiquery.Model
			
			
			# Determine if Physical or Virtual Platform
			If ($model -eq 'VMware Virtual Platform') {
				[string]$Platform = 'Virtual'
			}
			[boolean]$Success = $true
			[string]$Notes += 'WMI Query Success - '
			Else {
				[string]$Platform = 'Physical'
			}
		}
		
#		# If WMI Fails Try vCenter Query
#		If (($wmiconnect -eq $false) -and ($skipvimquery -eq $false)) {
#			Get-VmGuestInfo -ComputerName $ComputerName -vCenter $vCenter
#			If ($global:GetVmGuestInfo.Success -eq $true) {
#				$osver = $global:GetVmGuestInfo.OSVersion
#				$vimquerysuccess = $true
#				$lookupmethod = 'VIM'
#				[boolean]$Success = $true
#				$Notes += 'VIM Query Success - '
#			}
#			Else {
#				$vimquerysuccess = $false
#				$Notes += 'VIM Query Failed - '
#			}
#
#		} #/If WMI Query failed try vCenter
	} #/If Client not blank
	Else {
		[string]$Notes = 'Missing Host'
	}
	Get-Runtime -StartTime $SubStartTime
	
	# Create Results Custom PS Object
	$global:GetHardwareInfo = New-Object -TypeName PSObject -Property @{
		ComputerName = $ComputerName
		Success = $Success
		Notes = $Notes
		Starttime = $SubStartTime
		Endtime = $global:GetRunTime.Endtime
		Runtime = $global:GetRunTime.Runtime
		Platform = $Platform
		Model = $model
	}
}

#region Notes

<# Description
	Query Windows System for Hardware Information.
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Func_Invoke-Patching
	Get-HostInfo
#>

<# Dependencies
	Func_Get-Runtime
#>

<# Change Log
	1.0.0 - 10/11/2011
		Created
	1.0.1 - 02/06/2012
		Added Model to output
#>

#endregion Notes
