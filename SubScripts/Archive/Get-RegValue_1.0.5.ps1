#requires –version 2.0

Function Get-RegValue {
	Param (
		[parameter(Position=0,Mandatory=$true)][string]$ComputerName,
#		[parameter(Mandatory=$true)][string]$SubScripts,
		[parameter(Mandatory=$true)][string]$Assets,
		[parameter(Mandatory=$true)][string]$HKey,
		[parameter(Mandatory=$true)][string]$SubKey,
		[parameter(Mandatory=$false)][string]$String
	)
	
	# CLEAR VARIBLES
	[string]$Notes = ''
	[boolean]$Success = $false
	[datetime]$SubStartTime = Get-Date
	[string]$ComputerName = $ComputerName.ToUpper()
	
	[boolean]$keyopen = $false
	[boolean]$regconnect = $false
	[string]$StringType = 'Unknown'
	[string]$SubKeyList = 'None'
	$psdrive = $null
	$StringValue = $null
	
	# . "$SubScripts\Func_Get-Runtime_1.0.3.ps1"
		
	If ($global:GetRegValue) {
		Remove-Variable GetRegValue -Scope "Global"
	}
	# If localhost lookup then use PowerShell cmdlet instead of .Net object
	If ($ComputerName -eq 'localhost') {
		If ($HKey -eq 'LocalMachine') {
			[string]$psdrive = 'hklm'
		}
		If ($HKey -eq 'CurrentUser') {
			[string]$psdrive = 'hkcu'
		}
		[string]$key = $psdrive + ":\" + $SubKey
		$script:ErrorActionPreference = 'Stop'
		Try {
			$StringValue = Get-ItemProperty -Path $key | Select -ExpandProperty $String
			[boolean]$Success = $true
		}
		Catch {
			[string]$Notes += 'String not found '
			[boolean]$Success = $false
		}
		$script:ErrorActionPreference = 'Continue'
	}
	Else {
		# Open Registry on ComputerName using .NET Object
		$reg = $null
		$script:ErrorActionPreference = 'Stop'
		[int]$docount = 0
		Do {
			$docount++
			# Try to create .NET Object and connect to remote registry Hive 64-bit
			Try {
				# Create .NET 4.0 Object to remote registry (Registry Hive, Hostname)
				$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]$HKey,$ComputerName,[Microsoft.Win32.RegistryView]::Registry64)
				[boolean]$regconnect = $true
			}
			Catch {
				# CHECK THAT REMOTE REGISTRY SERVICE IS RUNNING
				# . "$SubScripts\Func_Invoke-PSService_1.0.1.ps1"
				$ServiceCheck = $null
					
				Try {
					$ServiceCheck = Get-Service -Name 'RemoteRegistry' -ComputerName $ComputerName -ErrorAction Stop
					[boolean]$CheckSuccess = $true
				}
				Catch {
					[boolean]$CheckSuccess = $false
					$Notes += "Failed to Get Remote Registry Service Status - "
				}
				If ($CheckSuccess -eq $true) {
					If ($ServiceCheck.Status -ne 'Started') {
#						Try {
#							Set-Service -Name 'RemoteRegistry' -StartupType Automatic -ErrorAction Stop
#						}
#						Catch {
#							$Notes += "Failed to Set Remote Registry Service to Automatic - "
#						}
#						Try {
#							Invoke-Command -ComputerName $ComputerName -ScriptBlock {Start-Service -Name 'RemoteRegistry'}
#						}
#						Catch {
#							$Notes += "Failed to Start Remote Registry Service to Automatic - "
#						}
#						[string]$RemoteCommand = 'NET START RemoteRegistry'
						[string]$RemoteCommand = 'setconfig remoteregistry auto'
						Invoke-PSService -ComputerName $ComputerName -RemoteCommand $RemoteCommand -Assets $Assets
						[string]$RemoteCommand = 'start remoteregistry'
						Invoke-PSService -ComputerName $ComputerName -RemoteCommand $RemoteCommand -Assets $Assets
						If ($global:InvokePSService.Success -eq $true) {
						}
						Sleep -Seconds 5
					}
					Else {
						[string]$Notes += 'Remote Registry Status: ' + ($ServiceCheck.Status)
					}
				}
				[string]$Notes = 'Failed to Connect to Host'
				[boolean]$regconnect = $false
			}
		}
		Until (($regconnect -eq $true) -or ($docount -gt 3))
		$script:ErrorActionPreference = 'Continue'
		
		# Open SubKey if Connected
		If ($regconnect -eq $true) {
			$key = $null
			$script:ErrorActionPreference = 'Stop'
			Try {
				$key = $reg.OpenSubKey($SubKey)
				[boolean]$keyopen = $true #^ Found that this does not error if the SubKey is not found or correct. So changed 122 to only continue  if $key exists
			}
			Catch {
				[string]$Notes += 'SubKey Missing 1 '
				[boolean]$keyopen = $false
			}
			$script:ErrorActionPreference = 'Continue'
			# Get Value if SubKey Connected without errors
			If ($key) {
				If ($String) {
					$script:ErrorActionPreference = 'Stop'
					Try {
						$StringValue = $key.GetValue($String)
						$StringType = $key.GetValueKind($String)
						[boolean]$Success = $true
					}
					Catch {
						[string]$Notes += 'Value Missing '
						[boolean]$Success = $false
					}
					$script:ErrorActionPreference = 'Continue'
				}
				Else {
					$script:ErrorActionPreference = 'Stop'
					Try {
						[array]$Valuenames = $key.GetValueNames()
						[boolean]$Success = $true
					}
					Catch {
						[string]$Notes += 'Could not Get String List '
						[boolean]$Success = $false
					}
					Try {
						[array]$SubKeyList = $key.GetSubKeyNames()
						[boolean]$Success = $true
					}
					Catch {
						[string]$Notes += 'Could not Get SubKey List '
						[boolean]$Success = $false
					}
					$script:ErrorActionPreference = 'Continue'
				}
				# Close Key
				If ($key) {
					$key.Close() | Out-Null
				}
			}
			Else {
				[string]$Notes += 'SubKey Missing 2 '
			}
			
			# CLOSE REGISTRY ON CLIENT
			If ($reg) {
				$reg.Close() | Out-Null
			}
		}
		Else {
			[string]$Notes += 'Failed to Connect to Host '
		}
	}	
	Get-Runtime -StartTime $SubStartTime
	# Create Results Custom PS Object
	$global:GetRegValue = New-Object -TypeName PSObject -Property @{
		ComputerName = $ComputerName
		Success = $Success
		Notes = $Notes
		RegHive = $HKey
		RegSubKey = $SubKey
		RegString = $String
		RegStringType = $StringType
		RegStringValue = $StringValue
		RegValueNames = $Valuenames
		RegSubKeyList = $SubKeyList
		KeyExists = $keyopen
		Connected = $regconnect
		Starttime = $SubStartTime
		Endtime = $global:GetRunTime.Endtime
		Runtime = $global:GetRunTime.Runtime
	}
	
}

#DEBUG
#	[string]$HKey = 'LocalMachine'
#	[string]$SubKey = 'SOFTWARE\Microsoft\PowerShell\1\PowerShellEngine'
#	[string]$String = 'RuntimeVersion'
#	
#	Get-RegValue -ComputerName orbbackup1 -HKey $HKey -SubKey $SubKey

#region Notes

<# Description
	Query Windows registry for a Value.
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Func_Get-PSVersion
	Func_Get-EPOVersion
	Func_Get-VSEVersion
	Func_Get-NBUVersion
	Func_Get-PendingReboot
	Func_Get-WUInfo
	Test-WSUSClient
	Get-HostInfo
#>

<# Dependencies
	None
#>

<# Change Log
	1.000 - 05/04/2011 (Beta)
		Created
	1.001 - 05/05/2011
		Added Runtime piece
	1.002 - 11/04/2011
		Found some issues with Pending Reboot and not getting corret info back
		Found = instead of -eq in If condition
	1.003 - 11/07/2011
		Changed RegStringValue to RegValueNames
	1.0.4 - 04/20/2012
		Changed client to computername
		Moved Notes to bottom
		Fixed some strict variable types from String to boolean
	1.0.4 - 04/23/2012
		Added PSService drafted section to turn on Remote Registry service is off. ^WIP
#>

<# To Do List

#>

<# Sources

#>

#endregion Notes

