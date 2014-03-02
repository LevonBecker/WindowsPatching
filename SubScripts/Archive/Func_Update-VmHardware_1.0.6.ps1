#requires –Version 2.0

Function Update-VmHardware {
	Param (
		[parameter(Position=0,Mandatory=$true)][string]$ComputerName,
		[parameter(Mandatory=$true)][string]$SubScripts,
		[parameter(Mandatory=$false)][switch]$StayConnected,
		[parameter(Mandatory=$true)][string]$vCenter,
		[parameter(Mandatory=$false)][boolean]$UseAltViCredsBool = $false,
		[parameter(Mandatory=$false)]$ViCreds,
		[parameter(Mandatory=$true)][string]$Version
	)
	# VARIABLES
	[string]$Notes = ''
	[boolean]$Success = $false
	[datetime]$SubStartTime = Get-Date
	[string]$ComputerName = $ComputerName.ToUpper()
	
	$VmView = $null
	$GetVM = $null
	[boolean]$VmFound = $false
	[string]$LatestVersion = 'Unknown'
	
	. "$SubScripts\Func_Connect-ViHost_1.0.7.ps1"
	. "$SubScripts\Func_Disconnect-ViHost_1.0.1.ps1"
	. "$SubScripts\Func_Get-Runtime_1.0.3.ps1"
	
	If ($Global:UpdateVmHardware) {
			Remove-Variable UpdateVmHardware -Scope "Global"
	}
	
	#region Tasks
		
		If ($UseAltViCredsBool -eq $true) {
			If ($ViCreds) {
				Connect-VIHost -ViHost $vCenter -SubScripts $SubScripts -AltViCreds -ViCreds $ViCreds
			}
			Else {
				Connect-VIHost -ViHost $vCenter -SubScripts $SubScripts -AltViCreds
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
				If ($Version -eq '4') {
					[string]$LatestVersion = 'vmx-04'
				}
				If ($Version -eq '7') {
					[string]$LatestVersion = 'vmx-07'
				}
				If ($Version -eq '8') {
					[string]$LatestVersion = 'vmx-08'
				}
				$VmView = Get-View -VIObject $GetVM
				$VmView.UpgradeVM_Task($LatestVersion) | Out-Null
				[int]$count = '0'
				Do {
					Sleep -Seconds 1
					$count++
				}
				# Wait for Version to be correct or 15 minutes
				Until ((((get-vm -Name $ComputerName) | get-view).Config.Version -eq $LatestVersion) -or ($count -eq 900))
				
				$GetVM = Get-VM -Name $ComputerName -ErrorAction Stop
				$VmView = Get-View -VIObject $GetVM
				[string]$GuestVersion = $VmView.Config.Version
				If ($GuestVersion -eq $LatestVersion) {
					[boolean]$Success = $true
				}
				
			} #/If VM Found
		} #/If ViConnect was successful
		Else {
			[string]$Notes += 'ViHost Connection Failed '
		}
		If ($StayConnected.IsPresent -eq $false) {
			Disconnect-VIHost	
		}

	#endregion Tasks
	
	Get-Runtime -StartTime $SubStartTime
	
	# Create Results Custom PS Object
	$Global:UpdateVmHardware = New-Object -TypeName PSObject -Property @{
		ComputerName = $ComputerName
		vCenter = $vCenter
		ViConnect = $Global:ConnectViHost.VIConnect
		VmFound = $VmFound
		UpgradeVersion = $LatestVersion
		Notes = $Notes
		Success = $Success
		Starttime = $SubStartTime
		Endtime = $Global:GetRunTime.Endtime
		Runtime = $Global:GetRunTime.Runtime
	}
}

#region Notes

<# Description
	Upgrade Guest VM Hardware Version to Version latest version based on the host it is on.
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
	Func_Connect-ViHost
	Func_Disconnect-ViHost
#>

<# Change Log
	1.0.0 - 02/14/2011 (Stable)
		Created
	1.0.1 - 05/09/2011 (WIP)
		Converted output to PSobject.
		Added Runtime
		Added use of sub scripts to connect to Vihost
	1.0.2 - 05/13/2011
		Renamed incorrect PSObject name from GetVmHardware to UpdateVmHardware
	1.0.3 - 10/02/2011
		Added support for ESXi 5.0
		Added Version Parameter
		Added UpgradeVersion output
	1.0.4 - 11/10/2011
		Added more parameter settings
		Added $UseAltViCredsBool and $ViCreds
	1.0.5 - 11/11/2011
		Changed to use Func_Connect-ViHost_1.0.3
#>

<# To Do List

#>

<# Sources

#>

#endregion Notes
