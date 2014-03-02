#requires –version 2.0

Function Get-WUInfo {
	Param (
		[parameter(Position=0,Mandatory=$true)][string]$ComputerName,
		[parameter(Mandatory=$true)][string]$Assets,
		[parameter(Mandatory=$true)][string]$UpdateServerURL
	)
	# VARIABLES
	[string]$Notes = ''
	[boolean]$Success = $false
	[datetime]$SubStartTime = Get-Date
	[string]$ComputerName = $ComputerName.ToUpper()
	
	[boolean]$failed = $false
	
	# REMOVE EXISTING OUTPUT PSOBJECT	
	If ($global:GetWUInfo) {
		Remove-Variable GetWUInfo -Scope "Global"
	}
	
	#region Tasks
	
		#region Get WUServer
			
			[string]$HKey = 'LocalMachine'
			
			# GET WU SERVER Value
			# HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\WUServer
			[string]$SubKey = 'SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
			[string]$String = 'WUServer'
			Get-RegValue -ComputerName $ComputerName -Assets $Assets -HKey $HKey -SubKey $SubKey -String $String
			If ($global:GetRegValue.Success -eq $true) {
				[string]$wuserver = $global:GetRegValue.RegStringValue
			}
			Else {
				[boolean]$failed = $true
				[string]$wuserver = 'Error'
			}
			
		#endregion Get WUServer
		
		#region Get WU Status Server
		
			# GET WU STATUS SERVER Value
			# HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\WUStatusServer
			[string]$SubKey = 'SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
			[string]$String = 'WUStatusServer'
			Get-RegValue -ComputerName $ComputerName -Assets $Assets -HKey $HKey -SubKey $SubKey -String $String 
			If ($global:GetRegValue.Success -eq $true) {
				[string]$wustatusserver = $global:GetRegValue.RegStringValue
			}
			Else {
				[boolean]$failed = $true
				[string]$wustatusserver = 'Error'
			}
			
		#endregion Get WU Status Server	
		
		#region Get Use WUServer
		
			# GET Use WU Server Value
			# HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU\UseWUServer
			[string]$SubKey = 'SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
			[string]$String = 'UseWUServer'
			Get-RegValue -ComputerName $ComputerName -Assets $Assets -HKey $HKey -SubKey $SubKey -String $String
			If ($global:GetRegValue.Success -eq $true) {
				$Value = $global:GetRegValue.RegStringValue
				If ($Value -eq '1') {
					[boolean]$usewuserver = $true
				}
				Else {
					[boolean]$usewuserver = $false
				}
			}
			Else {
				[boolean]$failed = $true
				[string]$usewuserver = 'Error'
			}
			
		#endregion Get Use WUServer	
		
		#region Validation
			
			# Valid Registry Values
			If (($wuserver -eq $UpdateServerURL) -and ($wustatusserver -eq $UpdateServerURL)) {
				[boolean]$passedregaudit = $true
			}
			Else {
				[boolean]$failed = $true
				[boolean]$passedregaudit = $false
			}
			
		#endregion Validation

	
	#endregion Tasks
	
	# CHECK SUCESS
	If ($failed -eq $false) {
		[boolean]$Success = $true
	}
	
	Get-Runtime -StartTime $SubStartTime
	
	# Create Results Custom PS Object
	$global:GetWUInfo = New-Object -TypeName PSObject -Property @{
		ComputerName = $ComputerName
		Success = $Success
		Notes = $Notes
		Starttime = $SubStartTime
		Endtime = $global:GetRunTime.Endtime
		Runtime = $global:GetRunTime.Runtime
		WUServer = $wuserver
		WUStatusServer = $wustatusserver
		WUServerOK = $passedregaudit
		UseWUServer = $usewuserver
	}
}

#region Notes

<# Description
	Get Windows Update Client Settings information from remote computer.
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Get-HostInfo
	Test-WSUSClient
#>

<# Dependencies
	Get-Runtime
#>

<# Change Log
1.0.0 - 02/06/2012
	Created
1.0.1 - 04/20/2012
	Moved Notes to end
	Renamed client to computername
	Fixed some strict var types from String to boolean
1.0.3 - 01/04/2013
	Removed -SubScript parameter from all subfunction calls.
	Removed dot sourcing subscripts because all are loaded when the module is imported now.
#>


#endregion Notes
