#requires –version 2.0

Function Get-IPConfig {
	Param (
		[parameter(Position=0,Mandatory=$true)][string]$ComputerName,
		[parameter(Mandatory=$true)][string]$SubScripts
	)
	# CLEAR VARIBLES
	[string]$Notes = ''
	[boolean]$Success = $false
	[datetime]$SubStartTime = Get-Date
	[string]$ComputerName = $ComputerName.ToUpper()
	
	$wmiquery = $null
	[boolean]$WmiConnected = $false
	[string]$IPConfig = 'Unknown'
	
	. "$SubScripts\Func_Get-Runtime_1.0.3.ps1"
		
	If ($global:GetIPConfig) {
		Remove-Variable GetIPConfig -Scope "Global"
	}
	
	If ($ComputerName) {
		Try {
			[array]$wmiquery = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName $ComputerName -ErrorAction Stop -ErrorVariable wmierror
			[boolean]$WmiConnected = $true
		}
		Catch {
			$Notes = 'ERROR: WMI Failed - '
			If ($geterror -like "*The RPC server is unavailable*") {
				[string]$Notes += 'The RPC server is unavailable'
				[boolean]$WmiConnected = $false
			}
		}
		
		If ($WmiConnected -eq $true) {
#			[Management.Automation.PSCustomObject]
			$IPConfigObj = $wmiquery | Select -Property Description,DHCPEnabled,IPAddress,IPSubnet,DefaultIPGateway,DNSServerSearchOrder,DNSDomainSuffixSearchOrder,WINSPrimaryServer,WINSSecondaryServer
			If ($IPConfigObj) {
				[boolean]$Success = $true
				[string]$Notes += 'Completed '
				[string]$IPConfig = $IPConfigObj | Out-String
			}
		}
	}
	Else {
		$Notes += 'ComputerName Missing '
	}
	Get-Runtime -StartTime $SubStartTime
	# Create Results Custom PS Object
	$global:GetIPConfig = New-Object -TypeName PSObject -Property @{
		ComputerName = $ComputerName
		Success = $Success
		Notes = $Notes
		WMIConnected = $WmiConnected
		IPConfig = $IPConfig
		Starttime = $SubStartTime
		Endtime = $global:GetRunTime.Endtime
		Runtime = $global:GetRunTime.Runtime
	}
}

#region Notes

<# Description
	Pull the network adapter IP Configuration of a remote ComputerName.
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Func_Invoke-Patching
#>

<# Dependencies
	Func_Get-Runtime
#>

<# Change Log
	1.0.0 - 02/15/2011 (Beta)
		Created
	1.0.1 - 04/22/2011 (Stable)
		Changed Break command to Return
	1.0.2 - 05/05/2011
		Adding PSObject Output
		Added Runtime recording
	1.0.3 - 04/20/2012
		Moved Notes to bottom
		Changed client to ComputerName
		Added some strict variable types
		Added parameter settings
	1.0.5 - 07/30/2012
		Removed [Management.Automation.PSCustomObject] strict variable type
#>

<# To Do List

#>

<# Sources

#>

#endregion Notes
