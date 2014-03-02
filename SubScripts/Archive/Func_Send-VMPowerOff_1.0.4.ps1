#requires –version 2.0

Function Send-VMPowerOff {
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
	[string]$VmPowerState = 'Unknown'
	[boolean]$VmFound = $false
	[boolean]$VmTurnedOff = $false
	
	. "$SubScripts\Func_Connect-ViHost_1.0.7.ps1"
	. "$SubScripts\Func_Disconnect-ViHost_1.0.1.ps1"
	. "$SubScripts\Func_Get-Runtime_1.0.3.ps1"
	
	If ($Global:SendVMPowerOff) {
			Remove-Variable SendVMPowerOff -Scope "Global"
	}
	
	#region Task
		
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
				$GetVM = Get-VM $ComputerName -ErrorAction Stop
				[boolean]$VmFound = $true
			}
			Catch {
				[string]$Notes += 'VM Not Found '
				[boolean]$VmFound = $false
			}
			If ($VmFound -eq $true) {
				$VmView = Get-View -VIObject $GetVM
				If ($GetVM.PowerState -eq 'PoweredOn') {
					# DIFFERENT METHOD TO SHUTDOWN IF NO VMTOOLS
					If ($VmView.Guest.ToolsStatus -eq "toolsNotInstalled") {
						Stop-VM -VM $ComputerName -Confirm:$false -RunAsync | Out-Null
						[string]$Notes += 'Stop-VM Use - '
					}
					# IF VMTOOLS INSTALLED
					Else {
						Shutdown-VMGuest -VM $ComputerName -Confirm:$false | Out-Null
						[string]$Notes += 'Shutdown-VMGuest Used - '
					}
					[int]$count = 0
					Do {
						Sleep -Seconds 1
						$count++
					}
					# Wait for PowerState to be off or 15 minutes
					Until (((Get-VM -Name $ComputerName).PowerState -eq 'PoweredOff') -or ($count -eq 900))
					
					# If Safe Shutdown through Vmtools fails then force poweroff
					If ($count -ge 900) {
						Stop-VM -VM $ComputerName -Confirm:$false -RunAsync | Out-Null
						[string]$Notes += 'Stop-VM Use because Shutdown-VMGuest Failed - '
					}
					[int]$count = 0
					Do {
						Sleep -Seconds 1
						$count++
					}
					# Wait for PowerState to be off or 15 minutes
					Until (((Get-VM -Name $ComputerName).PowerState -eq 'PoweredOff') -or ($count -eq 900))
					
					[string]$VmPowerState = (Get-VM -Name $ComputerName).PowerState
					If ($VmPowerState -eq 'PoweredOff') {
						[boolean]$VmTurnedOff = $true
						[string]$Notes += 'Completed '
						[boolean]$Success = $true
					}
					Else {
						[string]$Notes += 'Timed Out '
					}
				} #/If PoweredOn
				Else {
					[string]$Notes += 'Already Powered Off '
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
		
	#endregion Task
	
	Get-Runtime -StartTime $SubStartTime
	
	# Create Results Custom PS Object
	$Global:SendVMPowerOff = New-Object -TypeName PSObject -Property @{
		ComputerName = $ComputerName
		vCenter = $vCenter
		ViConnect = $Global:ConnectViHost.VIConnect
		VmFound = $VmFound
		VmTurnedOff = $VmTurnedOff
		Notes = $Notes
		Success = $Success
		VmPowerState = $VmPowerState
		Starttime = $SubStartTime
		Endtime = $Global:GetRunTime.Endtime
		Runtime = $Global:GetRunTime.Runtime
	}
}
# DEBUG
#Send-VMPowerOff -ComputerName orbbackup1

#region Notes

<# Description
	Function to Power Off a VM Guest.
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Func_Run-Patching.ps1
#>

<# Dependencies
	Func_Get-Runtime
	Func_Connect-ViHost
	Func_Disconnect-ViHost
#>

<# Change Log
	1.0.0 - 02/14/2011 (WIP)
		Created
	1.0.1 - 05/09/2011 (WIP)
		Converted output to PSobject.
		Added Runtime
		Added use of sub scripts to connect to Vihost
	1.0.2 - 11/10/2011
		Added more parameter settings
		Added $UseAltViCreds and $ViCreds
	1.0.3 - 11/11/2011
		Changed to use Func_Connect-ViHost
#>

<# To Do List

#>

<# Sources

#>

#endregion Notes
