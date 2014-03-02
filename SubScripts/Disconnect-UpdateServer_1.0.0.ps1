#requires –version 2.0

Function Disconnect-UpdateServer {

	#region Help

	<#
	.SYNOPSIS
		Disconnect from WSUS Server.
	.DESCRIPTION
		Disconnect from WSUS Server.
	.NOTES
		VERSION:    1.0.0
		AUTHOR:     Levon Becker
		EMAIL:      PowerShell.Guru@BonusBits.com 
		ENV:        Powershell v2.0, WSUS 3.x Binaries
		TOOLS:      PowerGUI Script Editor
	.INPUTS
	.OUTPUTS
	.EXAMPLE
		Disconnect-UpdateServer 
	.LINK
		http://wiki.bonusbits.com/main/PSScript:Connect-UpdateServer
		http://wiki.bonusbits.com/main/PSModule:WindowsPatching
		http://wiki.bonusbits.com/main/HowTo:Enable_.NET_4_Runtime_for_PowerShell_and_Other_Applications
		http://wiki.bonusbits.com/main/HowTo:Setup_PowerShell_Module
		http://wiki.bonusbits.com/main/HowTo:Enable_Remote_Signed_PowerShell_Scripts
	#>

	#endregion Help

	#region Parameters

		[CmdletBinding()]
		Param ()

	#endregion Parameters
		
	#region Variables

		
		[datetime]$SubStartTime = Get-Date
		
		# REMOVE EXISTING OUTPUT PSOBJECT	
		If ($Global:DisconnectUpdateServer) {
			Remove-Variable DisconnectUpdateServer -Scope "Global"
		}

	#endregion Variables
	
	#region Tasks
	
		#region Disconnect from WSUS Server
		
			If ($Global:ConnectedWsusServer) {
				Try {
					Remove-Variable ConnectedWsusServer -Scope "Global"
					[boolean]$Success = $true
				}
				Catch {
					[boolean]$Success = $false
				}
			}
			Else {
				[boolean]$Success = $true
				Write-Verbose 'Already removed'
			}
		
		#endregion Disconnect from WSUS Server
	
	#endregion Tasks
	
	#region Results
	
		Get-Runtime -StartTime $SubStartTime
		
		# Create Results Custom PS Object
		$Global:DisconnectUpdateServer = New-Object -TypeName PSObject -Property @{
			Success = $Success
			Errors = $Errors 
			Starttime = $SubStartTime
			Endtime = $global:GetRuntime.Endtime
			Runtime = $global:GetRuntime.Runtime
			Secure = $Secure
		}
	
	#endregion Results
}

#region Notes

<# Description
	This script can disconnect from the WSUS Server by removing the global varible.
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
