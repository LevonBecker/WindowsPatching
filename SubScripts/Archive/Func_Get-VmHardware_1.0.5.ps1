#requires –version 2.0

Function Get-VmHardware {
	Param (
		[parameter(Position=0,Mandatory=$true)][string]$ComputerName,
		[parameter(Mandatory=$true)][string]$SubScripts,
		[parameter(Mandatory=$false)][switch]$StayConnected,
		[parameter(Mandatory=$true)][string]$vCenter,
		[parameter(Mandatory=$false)][boolean]$UseAltViCredsBool = $false,
		[parameter(Mandatory=$false)]$ViCreds
	)
	# Variables
	[string]$Notes = ''
	[boolean]$Success = $false
	[datetime]$SubStartTime = Get-Date
	[string]$ComputerName = $ComputerName.ToUpper()
	
	$VmView = $null
	$GetVM = $null
	$GetVMhost = $null
	[boolean]$VmHostFound = $false
	[boolean]$VmFound = $false
	[string]$VmHost = 'Unknown'
	[string]$toolsstatus = 'Unknown'
	[string]$vmguestver = 'Unknown'
	[string]$VmHostVersion = 'Unknown'
	[string]$hostlatest = 'Unknown'
	
	. "$SubScripts\Func_Connect-ViHost_1.0.7.ps1"
	. "$SubScripts\Func_Disconnect-ViHost_1.0.1.ps1"
	. "$SubScripts\Func_Get-Runtime_1.0.3.ps1"
	
	If ($Global:GetVmHardware) {
			Remove-Variable GetVmHardware -Scope "Global"
	}
	
	#region Task
	
		If ($UseAltViCredsBool -eq $true) {
			If ($ViCreds) {
				Connect-VIHost -ViHost $vCenter -AltViCreds -ViCreds $ViCreds -SubScripts $SubScripts
			}
			Else {
				Connect-VIHost -ViHost $vCenter -AltViCreds -SubScripts $SubScripts
			}
		}
		Else {
			Connect-VIHost -ViHost $vCenter -SubScripts $SubScripts
		}
		
		If ($Global:ConnectViHost.VIConnect -eq $true) {
				Try {
					$GetVM = Get-VM -Name $ComputerName -ErrorAction Stop
					[boolean]$VmFound = $true
				}
				Catch {
					[string]$Notes += 'VM Not Found '
					[boolean]$VmFound = $false
				}
			If ($VmFound -eq $true) {
				$VmView = Get-View -VIObject $GetVM
				
				# GET VM ESX HOST NAME
				
				[string]$VmHost = $GetVM.VMHost.Name
				
				# GET VM ESX HOST VERSION
				Try {
					$GetVMhost = Get-VMHost $VmHost -ErrorAction Stop
					[boolean]$VmHostFound = $true
				}
				Catch {
					[string]$Notes += 'VMHost Not Found '
					[boolean]$VmHostFound = $false
				}
				If ($VmHostFound -eq $true) {
					[string]$VmHostVersion = $GetVMhost.Version
				}
				# GET CURRENT VM HARDWARE VERSION
				[string]$vmguestver = $VmView.Config.Version
				If ($vmguestver -match 'vmx-04') {
					[string]$guestversion = '4'
				}
				ElseIf ($vmguestver -match 'vmx-07') {
					[string]$guestversion = '7'
				}
				ElseIf ($vmguestver -match 'vmx-08') {
					[string]$guestversion = '8'
				}
				Else {
					[string]$guestversion = 'Not Match'
				}
				If ($VmHostVersion -match '3.') {
					[string]$hostlatest = '4'
				}
				ElseIf ($VmHostVersion -match '4.') {
					[string]$hostlatest = '7'
				}
				ElseIf ($VmHostVersion -match '5.') {
					[string]$hostlatest = '8'
				}
				$lookupfailed = $false
				# Check that both Host and Guest Information was gathered
				If (($VmHostVersion -eq $null) -or ($VmHostVersion -eq '')) {
					[string]$Notes += 'VMHost Version Query Failed '
					[boolean]$lookupfailed = $true
				}
				If (($vmguestver -eq $null) -or ($vmguestver -eq '')) {
					[string]$Notes += 'VMGuest Version Query Failed '
					[boolean]$lookupfailed = $true
				}
				If ($lookupfailed -eq $false) {
					If (($VmHostVersion -match '3.') -and ($vmguestver -match 'vmx-04')) {
						[boolean]$VmHardwareOK = $true
					}
					Elseif (($VmHostVersion -match '4.') -and ($vmguestver -match 'vmx-07')) {
						[boolean]$VmHardwareOK = $true
					}
					Elseif (($VmHostVersion -match '5.') -and ($vmguestver -match 'vmx-08')) {
						[boolean]$VmHardwareOK = $true
					}
					Else {
						[boolean]$VmHardwareOK = $false
					}
				}
				Else {
					[string]$Notes += 'ERROR: Failed all version evaluation conditions '
				}
			} #/If VM Found
		} #/If ViConnect was successful
		Else {
			[string]$Notes += 'ViHost Connection Failed '
		}
		
	#endregion Task	
		
	If ($StayConnected.IsPresent -eq $false) {
		Disconnect-VIHost	
	}
	
	# CHECK SUCCESS
	If ($lookupfailed -eq $false) {
		[boolean]$Success = $true
	}
	Get-Runtime -StartTime $SubStartTime
	# Create Results Custom PS Object
	$Global:GetVmHardware = New-Object -TypeName PSObject -Property @{
		ComputerName = $ComputerName
		Notes = $Notes
		Success = $Success
		Starttime = $SubStartTime
		Endtime = $Global:GetRunTime.Endtime
		Runtime = $Global:GetRunTime.Runtime
		vCenter = $vCenter
		ViConnect = $Global:ConnectViHost.VIConnect
		VmFound = $VmFound
		VmHostFound = $VmHostFound
		VmHost = $VmHost
		VmHostVersion = $VmHostVersion
		VmGuestVersion = $vmguestver
		GuestVersion = $guestversion
		VmHostLatest = $hostlatest
		VmHardwareOK = $VmHardwareOK
	}
}

#region Notes

<# Description
	Function to get the status of Vmware Tools on a VM Guest.
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Func_Run-Patching
#>

<# Dependencies
	Func_Get-Runtime
	Func_Connect-ViHost
	Func_Disconnect-ViHost
#>

<# Change Log
	1.0.0 - 02/15/2011 (WIP)
		Created
	1.0.1 - 05/09/2011 (WIP)
		Converted output to PSobject.
		Added Runtime
		Added use of sub scripts to connect to Vihost
	1.0.2 - 10/02/2011
		Added success check section at end
		Added support for ESXi 5.0 Hardware version 8
		Added VmHostVersion output
	1.0.3 - 11/10/2011
		Added more parameter settings
		Added $UseAltViCredsBool and $ViCreds
	1.0.4 - 11/11/2011
		Changed to use Func_Connect-ViHost_1.0.7.ps1
#>

#endregion Notes
