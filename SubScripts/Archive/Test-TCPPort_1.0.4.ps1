#requires –version 2.0

Function Test-TCPPort {
	Param (
		[parameter(Position=0,Mandatory=$true)][string]$ComputerName,
#		[parameter(Mandatory=$true)][string]$SubScripts,
		[parameter(Mandatory=$true)][int]$Port,
		[parameter(Mandatory=$false)][int]$Timeout = '120'
	)
	# VARIABLES
	[string]$Notes = ''
	[boolean]$Success = $false
	[datetime]$SubStartTime = Get-Date
	[string]$ComputerName = $ComputerName.ToUpper()		

	[boolean]$portopen = $false
	[boolean]$netsocketmade = $false
	
	If ($global:TestTCPPort) {
		Remove-Variable TestTCPPort -Scope "Global"
	}
	
	# . "$SubScripts\Func_Get-Runtime_1.0.3.ps1"
	
	#endregion Tasks
	
		$netsocket = $null
		$script:ErrorActionPreference = 'Stop'
		Try {
			# Create .Net Socket Object (Have to recreate each time because the Connect method changes the object)
			$netsocket = New-Object System.Net.Sockets.Socket -ArgumentList $([System.Net.Sockets.AddressFamily]::InterNetwork),$([System.Net.Sockets.SocketType]::Stream),$([System.Net.Sockets.ProtocolType]::Tcp)
			[boolean]$netsocketmade = $true
		}
		Catch {
			[string]$Notes += 'Net Socket Object Creation Failure '
			[boolean]$netsocketmade = $false
		}
		$script:ErrorActionPreference = 'Continue'
		If ($netsocketmade -eq $true) {
			$script:ErrorActionPreference = 'Stop'
			# Try to connect to port (Need Try/Catch because it will error if can't connect)
			Try {
			    $netsocket.Connect($ComputerName,$Port)
			    [boolean]$portopen = $netsocket.Connected
			    $netsocket.Close()
				# ^Need to look at if should split this up for better error handling
			}
			Catch {
			    [string]$Notes += "TCP Port $Port Not Open "
				[boolean]$portopen = $false
			}
			$script:ErrorActionPreference = 'Continue'
			If ($portopen -eq $true) {
				[boolean]$Success = $true
				[string]$Notes += 'Completed'
			}
			Elseif ($portopen -eq $false) {
				[boolean]$Success = $true
				[string]$Notes += 'Completed'
			}
			Else {
				[string]$Notes += 'Socket Error'
			}
		}

	#endregion Tasks
	
	Get-Runtime -StartTime $SubStartTime
	
	$global:TestTCPPort = New-Object -TypeName PSObject -Property @{
		ComputerName = $ComputerName
		Success = $Success
		Notes = $Notes
		Starttime = $SubStartTime
		Endtime = $global:GetRunTime.Endtime
		Runtime = $global:GetRunTime.Runtime
		TCPPort = $Port
		PortOpen = $portopen
	}
}

#region Notes

<# Description
	Tests if can connect to a TCP Port on a ComputerName.
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Func_Restart-Host
	Func_Send-VMPowerOn
#>

<# Dependencies
	Func_Get-Runtime
#>

<# Change Log
	1.000 - 04/22/2011 (Beta)
		Created.
	1.001 - 05/02/2011
		Continued creation and testing
	1.002 - 02/10/2012
		Cleaned up code
		Added parameter settings
		Changed $ComputerName to $computer
		Added CalcRunTime
	1.0.3 - 04/20/2012
		Move Notes to end
		Change some parameter names
#>

<# Sources
	Example
		http://boeprox.wordpress.com/2010/09/11/scanning-ports-on-multiple-hosts/
		http://gallery.technet.microsoft.com/ScriptCenter/97119ed6-6fb2-446d-98d8-32d823867131/
#>

#endregion Notes
