#requires –version 2.0

Function Connect-ViHost {
	Param (
		[parameter(Position=0,Mandatory=$true)][string]$ViHost,
		[parameter(Mandatory=$true)][string]$SubScripts,
		[parameter(Mandatory=$false)][switch]$AltViCreds,
		[parameter(Mandatory=$false)]$ViCreds
	)
	# VARIABLES
	[string]$Notes = ''
	[boolean]$Success = $false
	[datetime]$SubStartTime = Get-Date
	
	$checksnap = $null
	[boolean]$snapok = $false
	[boolean]$viconnect = $false
	[boolean]$donotdisvc = $false
	
	. "$SubScripts\Func_Get-Runtime_1.0.3.ps1"
	
	If ($global:ConnectViHost) {
			Remove-Variable ConnectViHost -Scope "Global"
	}
	
	$checksnap = Get-PSSnapin | select -ExpandProperty Name | Where-object {$_ -match "Vmware.VimAutomation.Core"}
	If ($checksnap -eq $null) {
		Try {
			# Change to wildcard for PowerCLI 5.0 because they have several Snapins now
			Add-PSSnapIn VMware.VimAutomation.Core -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
			[boolean]$snapok = $true
		}
		Catch {
			$Notes += 'Vmware PSSnapin Failed - '
			[boolean]$snapok = $false
		}
	}
	Else {
		[boolean]$snapok = $true
		[string]$Notes += 'PSSnapin Already Loaded - '
	}
	
	If ($snapok -eq $true) {
		# If not already connected to the VIServer then drop any current VIServer and connect to correct VIServer
		If ($global:DefaultVIServer.Name -notmatch $ViHost) {
			Disconnect-VIServer -Confirm:$false -Force:$true -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
			# If Alternate Credintials have been given then use them to connect to the VIServer
			If ($AltViCreds.IsPresent -eq $true) {
				If (!$ViCreds) {
					$ViCreds = Get-Credential
				}
				Try {
					Connect-VIServer -Server $ViHost -Credential $ViCreds -WarningAction SilentlyContinue -ErrorAction Stop | Out-Null
					[boolean]$viconnect = $true
				}
				Catch {
					[string]$Notes += 'Can not access vCenter - '
					[boolean]$viconnect = $false
				}
			}
			# Use credientals of user that launched the PowerShell Console
			Else {
				Try {
					Connect-VIServer -Server $ViHost -WarningAction SilentlyContinue -ErrorAction Stop | Out-Null
					[boolean]$viconnect = $true
				}
				Catch {
					[string]$Notes += 'Can not access vCenter - '
					[boolean]$viconnect = $false
				}
			}
		}
		Else {
			# Already connected so switch output variable
			[boolean]$viconnect = $true
			[string]$Notes += 'Already Connected to Correct VIServer '
		}
	}
	If (($snapok -eq $true) -and ($viconnect -eq $true)) {
		[boolean]$Success = $true
	}
	
	Get-Runtime -StartTime $SubStartTime
	
	# Create Results Custom PS Object
	$global:ConnectViHost = New-Object -TypeName PSObject -Property @{
		Notes = $Notes
		Success = $Success
		Starttime = $SubStartTime
		Endtime = $global:GetRunTime.Endtime
		Runtime = $global:GetRunTime.Runtime
		VIHost = $ViHost
		VIConnect = $viconnect
		VISnapOK = $snapok
	}
}

#region Notes

<# Description
	PURPOSE:	Connect to vCenter or ViHost. 	
	AUTHOR:		Levon Becker
#>

<# Dependents
	Func_Run-Patching
	Func_Get-VmTools
	Func_Get-VmHardware
	Func_Update-VmTools
	Func_Upgrade-Vmhareware
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
	1.0.1 - 10/02/2011
		Fixed conditions that would fail if already connected. Wasn't checking $snapok
	1.0.2 - 11/10/2011
		Added more parameter settings
		Added $UseAltViCredsBool and $ViCreds
	1.0.3 - 11/11/2011
		Changed $global:DefaultVIServer to $global:DefaultVIServer.Name
		Added SnapOK to output
		Added Get-Runtime
	1.0.3 - 01/19/2012
		Added default value of False for $UseAltViCredsBool so if nothing passed it will not have a null value and fail the condition 
	1.0.4 - 01/19/2012
		Changed line 83 Add-PSSnapin Vmware* to Add-PSSnapin VMware.VimAutomation.Core
	1.0.5 - 03/28/2012
		Did some tweaks to get the altcreds to work.
#>

<# To Do List

#>

<# Sources

#>

#endregion Notes
