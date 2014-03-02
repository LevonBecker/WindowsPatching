#requires –version 2.0

Function Update-VmTools {
	Param (
		[parameter(Position=0,Mandatory=$true)][string]$ComputerName,
		[parameter(Mandatory=$true)][string]$SubScripts,
		[parameter(Mandatory=$false)][switch]$StayConnected,
		[parameter(Mandatory=$true)][string]$vCenter,
		[parameter(Mandatory=$false)][boolean]$UseAltViCredsBool = $false,
		[parameter(Mandatory=$false)]$ViCreds
	)
	$ErrorActionPreference = "inquire"
	
	# VARIABLES
	[string]$Notes = ''
	[boolean]$Success = $false
	[datetime]$SubStartTime = Get-Date
	[string]$ComputerName = $ComputerName.ToUpper()
	
#	[boolean]$VmFound = $false
#	[boolean]$updatetriggered = $false
#	$Task = $null
#	$TaskID = $null
#	$TaskStatus = $null
	
	. "$SubScripts\Func_Connect-ViHost_1.0.7.ps1"
	. "$SubScripts\Func_Disconnect-ViHost_1.0.1.ps1"
	. "$SubScripts\Func_Get-Runtime_1.0.3.ps1"
		
	If ($Global:UpdateVmTools) {
		Remove-Variable UpdateVmTools -Scope "Global"
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
#			# Get Virtual Machines object information
#			Try {
##				$VMGuest = Get-VMGuest $ComputerName -ErrorAction Stop #Does it by Guest Operating System
#				$GetVM = Get-VM -Name $ComputerName -ErrorAction Stop
#				[boolean]$VmFound = $true
#			}
#			Catch {
#				[boolean]$VmFound = $false
#				[string]$Notes += 'Get-VM Failed '
#			}
#			# Continue if VM was found
#			If ($VmFound -eq $true) {
#				Try {
					# TRIGGER UPDATE TOOLS WITHOUT REBOOT ALLOWED
#					$Task = $VMGuest | Update-Tools -NoReboot -RunAsync -ErrorAction Stop #Does it by Guest Operating System
					# -ErrorVariable $updateerror
#					$Task = $GetVM | Update-Tools -NoReboot -RunAsync -ErrorAction Stop #Removed 07/30/2012
#					$Task = Update-Tools -VM $ComputerName -NoReboot -RunAsync -ErrorAction Stop
#					$VMGuest | Update-Tools -NoReboot -ErrorAction Stop #05/02/2012
#					$Task = Update-Tools -VM $GetVM -NoReboot -RunAsync -ErrorAction Stop #fails 4/20/2012 say key added error, but runs
#					
#					Update-Tools -VM $ComputerName -NoReboot -ErrorAction Stop
#					[boolean]$UpdateTriggered = $true
#					[boolean]$Success = $true
#				}
#				Catch {
#					[string]$Notes += 'Update-Tools Command Failed '
##					$errors += $updateerror
#					[boolean]$UpdateTriggered = $false
#				}
#				Get-VMGuest -VM $ComputerName
				$progresspreference = "SilentlyContinue"
				Update-Tools -VM $ComputerName -NoReboot -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
				Sleep -Seconds 420
				[boolean]$Success = $true
#				$Task = (Update-Tools -VM $ComputerName -NoReboot -RunAsync -ErrorAction SilentlyContinue -WarningAction SilentlyContinue)
#				$TaskID = $Task.Id
#				Wait-Task -Task $Task -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
#				$GetTask = Get-Task | Where-Object {$_.Id -eq $TaskID}
#				If ($GetTask) {
#					$TaskState = $GetTask.State
#					If ($TaskState -eq 'Success') {
#						[boolean]$Success = $true
#					}
#				}
#				Else {
#					[string]$Notes += 'FAILED: Get-Task  '
#				}
				$progresspreference = "Continue"
				
				# If tools update was triggered pull associated task and wait for completion
#				If ($UpdateTriggered -eq $true) {
#					$TaskObjectID = $Task.Id
#					Wait-Task -Task $Task
#					$GetTask = Get-Task | Where-Object {$_.ObjectId -eq $TaskObjectID}
#					
#					If ($TaskStatus -ne $null) {
#						$TaskState = $GetTask.State
#					}
#					Else {
#						[string]$Notes += 'ERROR: Get-Task Issue '
#					}
#					
#					If ($TaskState -eq "Success") {
#						[boolean]$Success = $true
#						[string]$Notes += 'Completed '
#					}
#					Elseif ($TaskState -eq "Error") {
#						[string]$Notes += 'ERROR: Task State is Error '
#					}
#					Else {
#						[string]$Notes += 'ERROR: Task State not Success or Error'
#					}
#				}
#			}
#			Else {
#				[string]$Notes += 'Failed to find VM '
#			}
		}
		Else {
			[string]$Notes += 'FAILED: vCenter Connection '
		}
		If ($StayConnected.IsPresent -eq $false) {
			Disconnect-VIHost	
		}
		
	#endregion Tasks
	
	If (!$TaskID) {
		[string]$TaskID = 'ERROR'
	}
	If (!$TaskState) {
		[string]$TaskState = 'ERROR'
	}
	
	# Determine Success ^Done on line 84
#	If ($taskstate -eq "Success") {
#		[boolean]$Success = $true
#	}
	
	Get-Runtime -StartTime $SubStartTime
	# Create Results Custom PS Object
	$Global:UpdateVmTools = New-Object -TypeName PSObject -Property @{
		ComputerName = $ComputerName
		Notes = $Notes
		Success = $Success
		Starttime = $SubStartTime
		Endtime = $Global:GetRunTime.Endtime
		Runtime = $Global:GetRunTime.Runtime
		vCenter = $vCenter
		ViConnect = $Global:ConnectViHost.VIConnect
#		TaskID = $TaskID
#		UpdateTriggered = $UpdateTriggered
#		TaskState = $TaskState
	}
}

#region Notes

<# Description
	Function to upgrade Vmware Tools on VM Guest using PowerCLI snapin.
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
	1.0.0 - 02/15/2011 (Beta)
		Created
	1.0.1 - 05/06/2011
		Adding PSObject Output
		Added Runtime recording
	1.0.2 - 05/13/2011
		Rename Result PSObject to UpdateVmTools (Was GetIPConfig still)
	1.0.3 - 10/02/2011
		Changed task variable names
		Added function success condition to end
		Fixed Update command to include Get-Vmguest $ComputerName | (Fixed the failures)
		Added error handling for if VM is not found.
	1.0.4 - 10/11/2011
		Change Get-Vmguest to Get-VM, seemed to fix the failures
	1.0.5 - 11/10/2011
		Added more parameter settings
		Added $UseAltViCredsBool and $ViCreds
	1.0.6 - 11/11/2011
		Changed to use Func_Connect-ViHost
	1.0.7 - 04/20/2012
		Renamed ComputerName to computername
		Changed StayConnected to switch
	1.0.9 - 07/30/2012
		Changed Update-Tools command syntax... again...
#>

<# To Do List

#>

<# Sources

#>

#endregion Notes
