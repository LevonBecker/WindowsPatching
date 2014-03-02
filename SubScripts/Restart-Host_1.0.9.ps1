#requires –version 2.0

Function Restart-Host {
	param(
		[parameter(Position=0,Mandatory=$true)][string]$ComputerName
	)

	# Clear old psobject if present
	If ($global:RestartHost) {
		Remove-Variable RestartHost -Scope Global
	}
	
	# VARIABLES
	[string]$Notes = ''
	[boolean]$Success = $false
	[datetime]$SubStartTime = Get-Date
	[string]$ComputerName = $ComputerName.ToUpper()
		
	If ($ComputerName) {
		# Test that RPC Ports 135 and 445 are open (For Restart-Computer cmdlet to work)
		[boolean]$rpc135 = $false
		[boolean]$rpc445 = $false
		Test-TCPPort -ComputerName $ComputerName -Port '135' -Timeout '120'
		If ($global:TestTCPPort.PortOpen -eq $true) {
			[boolean]$rpc135 = $true
		}
		Test-TCPPort -ComputerName $ComputerName -Port '445' -Timeout '120'
		If ($global:TestTCPPort.PortOpen -eq $true) {
			[boolean]$rpc445 = $true
		}
		
		# If RPC Ports Open
		If (($rpc135 -eq $true) -and ($rpc445 -eq $true)) {
			# If ICMP (Ping) is open
			If ((Test-Connection -ComputerName $ComputerName -Count 2 -Quiet) -eq $true) {
				[boolean]$ping = $true
				[string]$Notes += 'ICMP Open - '
				# Trigger Reboot
				Restart-Computer -ComputerName $ComputerName -Force

				# Ping Until Not Pingable or times out
				[int]$pingcount = 0
				Do {
					$pingcount++
					Sleep -Seconds 1
					[boolean]$ping = Test-Connection -ComputerName $ComputerName -Count 2 -Quiet
				}
				# Ping for 30 minutes or not pingable
				Until (($ping -eq $false) -or ($pingcount -gt 1800))
				
				If ($pingcount -gt 1800) {
						[boolean]$ping = $true
				}
				[string]$Notes += "Shutdown Ping Count: $pingcount - "
				
				# If Shutdown (Can't Ping)
				If ($ping -eq $false) {
					[int]$pingcount = 0
					# Ping until get response or times out
					Do {
						$pingcount++
						Sleep -Seconds 1
						[boolean]$ping = Test-Connection -ComputerName $ComputerName -Count 2 -Quiet
					}
					Until (($ping -eq $true) -or ($pingcount -gt 1800))
					
					If ($pingcount -gt 1800) {
						[boolean]$ping = $false
					}
					[string]$Notes += "Startup Ping Count: $pingcount - "
					
					# If UP (Ping reply)
					If ($ping -eq $true) {
						# Check until RDP Port 3389 is Listening or times out
						[int]$rdpcount = 0
						Do {
							$rdpcount++
							Sleep -Seconds 1
							[boolean]$rdp = $false
							Test-TCPPort -ComputerName $ComputerName -Port '3389' -Timeout '120'
							If ($global:TestTCPPort.PortOpen -eq $true) {
								[boolean]$rdp = $true
							}
						}
						Until (($rdp -eq $true) -or ($rdpcount -gt 1800))
						[string]$Notes += "RDP Test Count: $rdpcount - "
						# If RDP response
						If ($rdp -eq $true) {
							[boolean]$Success = $true
							[string]$Notes += 'Completed '
						}
						Else {
							[string]$Notes += 'Failed RDP Check - '
						}
					} #If UP
					Else {
						[string]$Notes += 'Failed Power On - '
					}
				} #/IF Shutdown
				Else {
					[string]$Notes += 'Failed Shutdown - '
				}
			} #If Can Ping
			# ICMP may be blocked but still can remote reboot with RPC command
			Else {
				# Check if Port 3389 is Listening and not blocked
				[string]$Notes += 'ICMP Not Open - '
				[boolean]$rdp = $false
				Test-TCPPort -ComputerName $ComputerName -Port '3389' -Timeout '120'
				If ($global:TestTCPPort.PortOpen -eq $true) {
					[boolean]$rdp = $true
				}
				If ($rdp -eq $true) {
					# Trigger Reboot
					Restart-Computer -ComputerName $ComputerName -Force
					
					# Test RDP until not available or times out
					[int]$rdpcount = 0
					Do {
						$rdpcount++
						Sleep -Seconds 1
						[boolean]$rdp = $true
						Test-TCPPort -ComputerName $ComputerName -Port '3389' -Timeout '120'
						If ($global:TestTCPPort.PortOpen -eq $false) {
							[boolean]$rdp = $false
						}
					}
					Until (($rdp -eq $false) -or ($rdpcount -gt 1800))
					
					If ($rdpcount -gt 1800) {
						[boolean]$rdp = $true
					}
					[string]$Notes += "Shutdown RDP Test Count: $rdpcount - "
					
					# Test RDP Until Available or times out
					[int]$rdpcount = 0
					Do {
						$rdpcount++
						Sleep -Seconds 1
						[boolean]$rdp = $false
						Test-TCPPort -ComputerName $ComputerName -Port '3389' -Timeout '120'
						If ($global:TestTCPPort.PortOpen -eq $true) {
							[boolean]$rdp = $true
						}
					}
					Until (($rdp -eq $true) -or ($rdpcount -gt 1800))
					
					If ($rdpcount -gt 1800) {
						[boolean]$rdp = $false
					}
					[string]$Notes += "Startup RDP Test Count: $rdpcount - "
					
					If ($rdp -eq $true) {
						[boolean]$Success = $true
						[string]$Notes += 'Completed by testing RDP instead of ICMP '
					}
					Else {
						[string]$Notes += 'Failed using RDP test instead of ICMP '
					}
					Sleep -Seconds 30
				} #/If RDP open
				# RDP Port 3389 and ICMP not open
				Else {
					### WIP ###
					[string]$Notes += 'RDP Port 3389 Blocked '
				}
			}
		} #/If RPC TCP Port 135 and 445 open
		Else {
			[string]$Notes += 'RPC Ports 135/445 Blocked '
		}
	} #If Hostname present
	Else {
		[string]$Notes += 'Missing Hostname '
	}

	If ($global:TestTCPPort.PortOpen -eq $false) {
		[string]$Notes += $global:TestTCPPort.Notes
	}
	
	Get-Runtime -StartTime $SubStartTime
	
	# Temporary Fix ^^
	Sleep -Seconds 60
	
	# Create Results Custom PS Object
	$global:RestartHost = New-Object -TypeName PSObject -Property @{
		ComputerName = $ComputerName
		Success = $Success
		Starttime = $SubStartTime
		Endtime = $global:GetRunTime.Endtime
		Runtime = $global:GetRunTime.Runtime
		RebootTime = $global:GetRunTime.Runtime
		Notes = $Notes
	}
	
}

#region Notes

<# Description
	Reboot a remote computer and return results of task.
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Parent Script Dependents
	Get-IIS-Security
	Install-Patches
	Restart-Hosts
#>

<# Dependencies
	Test-TCPPort
#>

<# Change Log
1.0.0 - 02/15/2011 
	Created.
1.0.1 -	04/18/2011 
	Changed output variables to single output PSObject.
1.0.2 -	04/20/2011 (Stable)
	Added Parameter check for $computer.
	Rewrote logic to remove breaks so it won't completely stop any root scripts calling this function.
	Switched Success update to Guilty until proven innocent method.
	Cleaned up info section (This stuff).
	Cleaned up Port 3389 connection test section.
1.0.3 - 04/21/2011 (Stable)
	Added Logic to test ICMP before using loop that requires it.
	In some cases ICMP (Ping) may be blocked but RPC for the Reboot command still allowed.
	So basically, if the Restart-Computer will work but can't ping then just do a long wait
	and try to connect to the RDP Port 3389.
	Added RPC Port check at start (For Restart-Computer cmdlet to work).
	Added Reboot Runtime Timespan tracking and output.
1.0.4 - 05/02/2011
	Changed a lot to use the sub script Test-TCPPort.ps1
	Finished Secondary up testing using RDP Port 3389 if ICMP is blocked.
	Removed Try/Catch and Erroraction stop that was breaking sections not designed to be
	caught.
1.0.5 - 11/11/2011
	Bumped up timeout to 30 minutes (1800 seconds)
	Added Sleep -Second 1 to all the Do/Until loops
	Added more Notes for troubleshooting
	Added temp 2 minute wait at end
1.0.6 - 02/10/2012
	Added Port 445 and 139 check for SMB and NetBIOS (PSExec.exe)
	Updated to Test-TCPPort_1.002
	Changed $client to $computer
1.0.7 - 04/20/2012
	Moved Notes to end
	Renamed some parameters
	Switched to Test-TCPPort_1.0.3
1.0.9 - 01/04/2013
	Removed -SubScript parameter from all subfunction calls.
	Removed dot sourcing subscripts because all are loaded when the module is imported now.
#>

<# Sources
TCP Port Check
	http://poshcode.org/2392
#>

#endregion Notes
