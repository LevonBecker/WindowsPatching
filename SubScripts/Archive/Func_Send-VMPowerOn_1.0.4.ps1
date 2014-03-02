#requires –version 2.0

Function Send-VMPowerOn {
	Param (
		[parameter(Position=0,Mandatory=$true)][string]$ComputerName,
		[parameter(Mandatory=$true)][string]$SubScripts,
		[parameter(Mandatory=$false)][switch]$StayConnected = $false,
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
	[boolean]$vmturnedoff = $false
	[boolean]$VmTurnedOn = $false
	[boolean]$VmPingable = $false
	[boolean]$VmRDPAccessable = $false
	[boolean]$rdp = $false
	
	. "$SubScripts\Func_Connect-ViHost_1.0.7.ps1"
	. "$SubScripts\Func_Disconnect-ViHost_1.0.1.ps1"
	. "$SubScripts\Func_Get-Runtime_1.0.3.ps1"
	. "$SubScripts\Func_Test-TCPPort_1.0.4.ps1"
	
	If ($Global:TurnOnVM) {
			Remove-Variable TurnOnVM -Scope "Global"
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
				$GetVM = Get-VM -Name $ComputerName -ErrorAction Stop
				[boolean]$VmFound = $true
			}
			Catch {
				[string]$Notes += 'VM Not Found '
				[boolean]$VmFound = $false
			}
			If ($VmFound -eq $true) {
				$VmView = Get-View -VIObject $GetVM
				If ($GetVM.PowerState -eq 'PoweredOff') {
					# Trigger Powerup
					Start-VM -VM $ComputerName -RunAsync | Out-Null
					# Keep checking until PowerState = PoweredON
					[int]$count = 0
					Do {
						Sleep -Seconds 1
						$count++
					}
					# Wait for PowerState to be on or 15 minutes
					Until (((Get-VM -Name $ComputerName).PowerState -eq 'PoweredOn') -or ($count -eq 900))
					
					# Check Powerstate vs timeout
					[string]$VmPowerState = (Get-VM $ComputerName).PowerState
					If ($VmPowerState -eq 'PoweredOn') {
						[boolean]$VmTurnedOn = $true
						[string]$Notes += 'Powered On - '
						[boolean]$Success = $true
						
						# Ping until pingable
						[boolean]$ping = $false
						[int]$pingcount = 0
						# Ping until get response or times out
						Do {
							$pingcount++
							[boolean]$ping = Test-Connection -ComputerName $ComputerName -Count 2 -Quiet
						}
						Until (($ping -eq $true) -or ($pingcount -gt 900))
												
						# If UP (Ping reply)
						If ($ping -eq $true) {
							[boolean]$VmPingable = $true
							[boolean]$Success = $true
							# Check until RDP port 3389 is Listening or times out
							[int]$rdpcount = 0
							Do {
								$rdpcount++
								[boolean]$rdp = $false
								Test-TCPPort -ComputerName $ComputerName -SubScripts $SubScripts -port '3389' -timeout '120'
								If ($Global:TestTCPPort.PortOpen -eq $true) {
									[boolean]$rdp = $true
								}
							}
							Until (($rdp -eq $true) -or ($rdpcount -gt 300))
							
							# If RDP response
							If ($rdp -eq $true) {
								[boolean]$VmRDPAccessable = $true
								[boolean]$Success = $true
							}
							Else {
								[string]$Notes += 'Failed RDP Check '
							}
						} #If UP
						Else {
							[string]$Notes += 'Failed Power On '
						}
					} #/If Powered On
					Else {
						[string]$Notes += 'Timed Out '
					}
				} #/If VM Powered Off
				Else {
					[string]$Notes += 'Already Powered On '
					[boolean]$Success = $true
				}
				Sleep -Seconds 30
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
	$Global:TurnOnVM = New-Object -TypeName PSObject -Property @{
		ComputerName = $ComputerName
		vCenter = $vCenter
		ViConnect = $Global:ConnectViHost.ViConnect
		VmFound = $VmFound
		VmTurnedOn = $VmTurnedOn
		VmPingable = $VmPingable
		VmRDPAccessable = $VmRDPAccessable
		Notes = $Notes
		Success = $Success
		VmPowerState = $VmPowerState
		Starttime = $SubStartTime
		Endtime = $Global:GetRunTime.Endtime
		Runtime = $Global:GetRunTime.Runtime
	}
}
#	Start-VM -VM $ComputerName -RunAsync | Wait-Tools | Out-Null
#	$count = 0
#	Do {
#		sleep -Seconds 1
#		$count++
#	} 
#	Until (((get-vm $ComputerName).PowerState -eq 'PoweredOn') -or ($count -eq 600))
#			# This gives it a maximum of 10 minutes...
#	Sleep -Seconds 180 # Let machine boot

# DEBUG
#Send-VMPowerOn -ComputerName orbbackup1

#region Notes

<# Description
	Function to to Power On a VM Guest.
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
	Func_Test-TCPPort
#>

<# Change Log
	1.0.0 - 02/14/2011 (Beta)
		Created
	1.0.1 - 05/09/2011 (WIP)
		Converted output to PSobject.
		Added Runtime
		Added use of sub scripts to connect to Vihost
	1.0.2 - 11/10/2011
		Added more parameter settings
		Added $UseAltViCredsBool and $ViCreds
	1.0.3 - 11/11/2011
		Changed to use Func_Connect-ViHost_1.0.3
#>

<# To Do List

#>

<# Sources

#>

#endregion Notes
