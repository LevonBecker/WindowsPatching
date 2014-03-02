#requires –version 2.0

Function Reset-WindowsPatchingUI {

	Param (
	[parameter(Position=0,Mandatory=$true)][string]$StartingWindowTitle,
	[parameter(Position=1,Mandatory=$true)][array]$StartupVariables,
	[parameter(Mandatory=$false)][switch]$SkipPrompt
	)

	#region Tasks
	
		#region Prompt: Press any Key
		
			If ($SkipPrompt.IsPresent -eq $false) {
				Write-Host ''
				Write-Host "Press any key to continue ..."
				$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
			}
		
		#endregion Prompt: Press any Key
		
		#region Reset UI
		
			Clear
			$Host.UI.RawUI.WindowTitle = $StartingWindowTitle
			
			# Remove Global Variables
			Get-Variable -Scope Global | Select -ExpandProperty Name |
			Where-Object {$StartupVariables -notcontains $_} |
		    ForEach-Object {Remove-Variable -Name ($_) -Scope "Global" -Force}
			
			If ($Global:WindowsPatchingDefaults.NoTips -eq $true) {
				Show-WindowsPatchingHeader -NoTips
			}
			ElseIf ($Global:WindowsPatchingDefaults.NoHeader -eq $false) {
				Show-WindowsPatchingHeader
			}
			
			# Clear Errors
			$Error.Clear()
		
		#endregion Reset UI
	
	#endregion Tasks
	
}

#region Notes

<# Description
	Clean up the screen and variables when WindowsPatching CmdLet finishes.
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Test-WSUSClient
	Install-Patches
	Get-PendingUpdates
	Get-WSUSClients
	Get-WSUSFailedClients
	Move-WSUSClientToGroup
#>

<# Dependencies
#>

<# To Do List
	
#>

<# Change Log
1.0.0 - 04/27/2012
	Created
1.0.1 - 05/10/2012
	Added condition to check if Show-WindowsPatchingHeader is loaded before loading it.
	Added Subscripts to Show-WindowsPatchingHeader call
1.0.2 - 05/14/2012
	Switched to Show-WindowsPatchingHeader 1.0.2
1.0.3 - 10/22/2012
	Switched to Show-WindowsPatchingHeader 1.0.3
1.0.4 - 12/17/2012
	Switched to Show-WindowsPatchingHeader 1.0.4
	Added Switch parameter to skip prompt
1.0.5 - 01/04/2013
	Removed -SubScript parameter from all subfunction calls.
	Removed dot sourcing subscripts because all are loaded when the module is imported now.
1.0.6 - 01/14/2013
	Renamed WPM to WindowsPatching
#>

#endregion Notes
