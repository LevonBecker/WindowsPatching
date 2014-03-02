#requires –version 2.0

Function Connect-UpdateServer {

	#region Help

	<#
	.SYNOPSIS
		Connect to WSUS Server.
	.DESCRIPTION
		Connect to WSUS Server.
	.NOTES
		VERSION:    1.0.0
		AUTHOR:     Levon Becker
		EMAIL:      PowerShell.Guru@BonusBits.com 
		ENV:        Powershell v2.0, WSUS 3.x Binaries
		TOOLS:      PowerGUI Script Editor
	.INPUTS
		UpdateServer        WSUS Server Hostname
		UpdateServerPort    WSUS Server TCP Port
	.OUTPUTS
		Global PSObject
	.EXAMPLE
		Connect-UpdateServer -UpdateServer wsus01.domain.com
		Connect on default port 80
	.EXAMPLE
		Connect-UpdateServer -UpdateServer wsus01.domain.com -UpdateServerPort 443 
		Connect secure on port 443
	.EXAMPLE
		Connect-UpdateServer -UpdateServer wsus01.domain.com -UpdateServerPort 8530 
		Connect on unsecure port 8530
	.EXAMPLE
		Connect-UpdateServer -UpdateServer wsus01.domain.com -UpdateServerPort 8531 
		Connect on secure port 8531
	.PARAMETER UpdateServer
		Hostname for WSUS Server.
		Shortname or FQDN works.
	.PARAMETER UpdateServerPort
		TCP Port number to connect to the WSUS Server through IIS.
	.LINK
		http://wiki.bonusbits.com/main/PSScript:Connect-UpdateServer
		http://wiki.bonusbits.com/main/PSModule:WindowsPatching
		http://wiki.bonusbits.com/main/HowTo:Enable_.NET_4_Runtime_for_PowerShell_and_Other_Applications
		http://wiki.bonusbits.com/main/HowTo:Setup_PowerShell_Module
		http://wiki.bonusbits.com/main/HowTo:Enable_Remote_Signed_PowerShell_Scripts
	#>

	#endregion Help

	#region Parameters

		[CmdletBinding(DefaultParameterSetName = 'defaultport',ConfirmImpact = 'low')]
		Param (
			[Parameter(
		        Mandatory = $true,
		        Position = 0,
		        ParameterSetName = '',
		        ValueFromPipeline = $false)]
		        [string]$UpdateServer,                     
	#	    [Parameter(
	#	        Mandatory = $False,
	#	        Position = 1,
	#	        ParameterSetName = '',
	#	        ValueFromPipeline = $False)]
	#	        [switch]$SecureConnection,   
		    [Parameter(
		        Mandatory = $true,
		        Position = 1,
		        ParameterSetName = 'specificport',
		        ValueFromPipeline = $false)]
		        [ValidateSet("80","443","8530","8531" )] 
		        [int]$UpdateServerPort 
		)

	#endregion Parameters
		
	#region Variables

		[boolean]$Success = $false
		[datetime]$SubStartTime = Get-Date
		
		If (($UpdateServerPort -eq '443') -or ($UpdateServerPort -eq '8531')) {
	        $Secure = $True
	    } Else {
	        $Secure = $False
	    }

		# REMOVE EXISTING OUTPUT PSOBJECT	
		If ($Global:ConnectUpdateServer) {
			Remove-Variable ConnectUpdateServer -Scope "Global"
		}

	#endregion Variables
	
	#region Tasks
	
		#region Connect to WSUS Server
		
			If ($Global:ConnectedWsusServer) {
				Remove-Variable ConnectedWsusServer -Scope "Global"
			}
		
			$Script:ErrorActionPreference = 'stop'
			Try {
	            Switch ($pscmdlet.ParameterSetName) {
	                "defaultport" {
	                    $Global:ConnectedWsusServer = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($UpdateServer,$Secure)
	                }
	                "specificport" {
	                    $Global:ConnectedWsusServer = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($UpdateServer,$Secure,$UpdateServerPort)              
	                }               
	            }
	            [boolean]$Success = $true 
	        } 
			Catch {
#		            Write-Warning "Unable to connect to $($UpdateServer)!`n$($error[0])"
				Write-Host ''
				Write-Host "ERROR: Failed to Connect to WSUS Server ($UpdateServer)" -ForegroundColor White -BackgroundColor Red
				Write-Host ''
				Reset-WindowsPatchingUI -StartingWindowTitle $StartingWindowTitle -StartupVariables $StartupVariables
				Break
	        }
			$Script:ErrorActionPreference = 'continue'
		
		#endregion Connect to WSUS Server
	
	#endregion Tasks
	
	#region Results
	
		Get-Runtime -StartTime $SubStartTime
		
		# Create Results Custom PS Object
		$Global:ConnectUpdateServer = New-Object -TypeName PSObject -Property @{
			Success = $Success
			Errors = $Errors 
			Starttime = $SubStartTime
			Endtime = $global:GetRuntime.Endtime
			Runtime = $global:GetRuntime.Runtime
			Secure = $Secure
			UpdateServer = $UpdateServer
			UpdateServerPort = $UpdateServerPort
		}
	
	#endregion Results
}

#region Notes

<# Description
	This script can connect to a WSUS 3.x server if WSUS on current system.
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
