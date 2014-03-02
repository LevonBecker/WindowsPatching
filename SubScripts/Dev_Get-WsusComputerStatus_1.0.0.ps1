#requires –version 2.0

Function Get-WsusComputerStatus {
	
	#region Parameters

		[CmdletBinding()]
		Param (
			[parameter(Mandatory=$false,Position=0)][string]$FullDomainName
		)

	#endregion Parameters
	
	#region Variables

		[boolean]$Success = $false
		[datetime]$SubStartTime = Get-Date
		
		# REMOVE EXISTING OUTPUT PSOBJECT	
		If ($Global:GetWsusComputerStatus) {
			Remove-Variable GetWsusComputerStatus -Scope "Global"
		}

	#endregion Variables
	
	#region Tasks
	
		If ($Global:ConnectedWsusServer) {
			Write-Verbose "Creating Computer Scope Object"
			# [Microsoft.UpdateServices.Administration.UpdateScope]
        	$UpdateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
			
			Write-Verbose "Creating Computer Scope Object"
       	 	# [Microsoft.UpdateServices.Administration.ComputerTargetScope]
			$ComputerScope = New-Object Microsoft.UpdateServices.Administration.ComputerTargetScope
			
			If ($FullDomainName) {
				$ComputerScope.NameIncludes = $FullDomainName
				
				# [Microsoft.UpdateServices.Administration.UpdateSummaryCollection]
				$AllComputerStatus = $ConnectedWsusServer.GetSummariesPerComputerTarget($UpdateScope,$ComputerScope)
				$SelectedComputer = $AllComputerStatus | Where-Object {$_.Computer -eq $FullDomainName}

				If ($SelectedComputer.InstalledCount -ne $null) {
					$InstalledCount = $SelectedComputer.InstalledCount
				}
				Else {
					$InstalledCount = 'Unknown'
				}
				If ($SelectedComputer.NeededCount -ne $null) {
					$NeededCount = $SelectedComputer.NeededCount
				}
				Else {
					$NeededCount = 'Unknown'
				}
				If ($SelectedComputer.FailedCount -ne $null) {
					$FailedCount = $SelectedComputer.FailedCount
				}
				Else {
					$FailedCount = 'Unknown'
				}
			}
			Else {
				$SelectedComputer = 'N/A'
				$InstalledCount = 'N/A'
				$NeededCount = 'N/A'
				$FailedCount = 'N/A'
				
				# [Microsoft.UpdateServices.Administration.UpdateSummaryCollection]
				$AllComputerStatus = $ConnectedWsusServer.GetSummariesPerComputerTarget($UpdateScope,$ComputerScope)
			}
		}
		Else {
			[Boolean]$Success = $false
			[string]$Errors = 'Not Connected to WSUS Server'
		}

	#endregion Tasks
		
	#region Determine Success
	
		If ($AllComputerStatus) {
			[Boolean]$Success = $true
		}
		Else {
			[Boolean]$Success = $false
		}
	
	#endregion Determine Success
	
	#region Results
	
		Get-Runtime -StartTime $SubStartTime
		
		# Create Results Custom PS Object
		$Global:GetWsusComputerStatus = New-Object -TypeName PSObject -Property @{
			Success = $Success
			Errors = $Errors 
			Starttime = $SubStartTime
			Endtime = $global:GetRuntime.Endtime
			Runtime = $global:GetRuntime.Runtime
			AllComputerStatus = $AllComputerStatus
			SelectedComputer = $SelectedComputer
			InstalledCount = $InstalledCount
			NeededCount = $NeededCount
			FailedCount = $FailedCount
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
