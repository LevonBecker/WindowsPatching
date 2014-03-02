#requires –version 2.0

Function Get-WsusGroup {
	
	#region Parameters

		[CmdletBinding()]
		Param ()

	#endregion Parameters
	
	#region Variables

		[boolean]$Success = $false
		[datetime]$SubStartTime = Get-Date
		
		# REMOVE EXISTING OUTPUT PSOBJECT	
		If ($Global:GetWsusGroup) {
			Remove-Variable GetWsusGroup -Scope "Global"
		}

	#endregion Variables
	
	#region Tasks
	
		
		If ($Global:ConnectedWsusServer) {
			$AllGroups = $Global:ConnectedWsusServer.GetComputerTargetGroups()
#			$ConnectedWsusServer
			[array]$AllGroupNames = $AllGroups | Select-Object -ExpandProperty Name | Sort-Object
#			$TargetGroup = $Global:ConnectedWsusServer.GetComputerTargetGroups() | Where-Object {$_.Name -eq $WsusGroup}
		}
		Else {
			[Boolean]$Success = $false
			[string]$Errors = 'Not Connected to WSUS Server'
		}

	#endregion Tasks
	
	#region Results
	
		Get-Runtime -StartTime $SubStartTime
		
		# Create Results Custom PS Object
		$Global:GetWsusGroup = New-Object -TypeName PSObject -Property @{
			Success = $Success
			Errors = $Errors 
			Starttime = $SubStartTime
			Endtime = $global:GetRuntime.Endtime
			Runtime = $global:GetRuntime.Runtime
			AllGroups = $AllGroups
			AllGroupNames = $AllGroupNames
		}
	
	#endregion Results

}

#region Notes

<# Description
	This script can get a list of computers in a WSUS group.
#>

<# Author
	Levon Becker
	powershell.guru@bonusbits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Test-WSUSClient
	Get-WSUSClients
	Get-WSUSFailedClients
	Install-Patches
	Get-PendingPatches
	Move-WSUSClientToGroup
#>

<# Dependencies
	Get-Runtime
#>

<# Change Log
1.0.0 - 01/23/2013
	Created
#>

#endregion Notes
