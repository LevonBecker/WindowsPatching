#requires –version 2.0

Function Get-Domain {
	Param (
		[parameter(Position=0,Mandatory=$true)][string]$ComputerName,
		[parameter(Mandatory=$false)][switch]$StayConnected, #Not used yet
		[parameter(Mandatory=$false)][string]$vCenter,
		[parameter(Mandatory=$false)][boolean]$UseAltViCreds = $false,
		[parameter(Mandatory=$false)]$ViCreds,
		[parameter(Mandatory=$false)][switch]$SkipVimQuery
	)
	# Guilty until proven innocent
	[string]$Notes = ''
	[boolean]$Success = $false
	[datetime]$SubStartTime = Get-Date
	[string]$ComputerName = $ComputerName.ToUpper()
	
	[string]$hostdomain = 'Unknown'
	$wmiquery = $null
	[boolean]$wmiconnect = $false
	[boolean]$vimquerysuccess = $false
	[string]$lookupmethod = 'All Failed'
		
	If ($global:GetDomain) {
		Remove-Variable GetDomain -Scope "Global" | Out-Null
	}
	
	If ($ComputerName) {
		#region WMI QUERY
		
			Try {
				$wmiquery = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $ComputerName -ErrorAction Stop
				[boolean]$wmiconnect = $true
			}
			Catch {
				[string]$Notes += 'WMI Query Failed - '
				[boolean]$wmiconnect = $false
			}
			If ($wmiconnect -eq $true) {
				[string]$ComputerDomain = $wmiquery.Domain
				[string]$lookupmethod = 'WMI'
				[boolean]$Success = $true
			}
		
		#endregion WMI QUERY
		
		#region vCenter Query
		
			# IF WMI FAILS and Switch not set to skip, DO vCENTER QUERY
			If (($wmiconnect -eq $false) -and ($SkipVimQuery.IsPresent -eq $false)) {
				Get-VmGuestInfo -ComputerName $ComputerName -SubScripts $SubScripts -vCenter $vCenter -UseAltViCreds $UseAltViCreds -ViCreds $ViCreds
				If ($global:GetVmGuestInfo.Success -eq $true) {
					[string]$ComputerDomain = $global:GetVmGuestInfo.HostDomain
					[string]$vimquerysuccess = $true
					[string]$lookupmethod = 'VIM'
					[boolean]$Success = $true
				}
				Else {
					[boolean]$vimquerysuccess = $false
					[string]$Notes += 'VIM Query Failed - '
				}

			} #/If WMI Query failed try vCenter
		
		#endregion vCenter Query

	} #/If Client not blank
	Else {
		[string]$Notes = 'Missing Host'
	}
	Get-Runtime -StartTime $SubStartTime
	# Create Results Custom PS Object
	$global:GetDomain = New-Object -TypeName PSObject -Property @{
		ComputerName = $ComputerName
		Success = $Success
		Notes = $Notes
		Starttime = $SubStartTime
		Endtime = $global:GetRunTime.Endtime
		Runtime = $global:GetRunTime.Runtime
		HostDomain = $ComputerDomain
		LookupMethod = $lookupmethod
	}
}

#region Notes

<# Description
	Query Windows Host for the Domain Name it's joined to.
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Check-WSUSClient
#>

<# Dependencies
	Func_Get-Runtime
	Func_Get-VmGuestInfo
#>

<# Change Log
1.0.0 - 02/01/2012
	Created
1.0.1 - 04/20/2012
	Move Notes to end
	Renamed some parameters
	Fixed some strict variable types
	Changed SkipVimQuery boolean to switch parameter
1.0.2 - 05/02/2012
	Change SkipVimQuery to a switch
	More renames
1.0.3 - 12/14/2012
	Moved Get VMInfo dot source so it doesn't load if not needed.
#>

<# To Do List
#>

<# Sources
#>

#endregion Notes
