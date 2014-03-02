#requires –version 2.0

Function Reset-WPMUI {

	Param (
	[parameter(Position=0,Mandatory=$true)][string]$StartingWindowTitle,
	[parameter(Position=1,Mandatory=$true)][array]$StartupVariables,
	[parameter(Mandatory=$true)][string]$SubScripts
	)

	If ((Get-Command -Name "Show-WPMHeader" -ErrorAction SilentlyContinue) -eq $null){
		. "$SubScripts\Func_Show-WPMHeader_1.0.3.ps1"
	}

	#region Tasks
	
		# Prompt
		Write-Host ''
		Write-Host "Press any key to continue ..."
		$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		
		# Reset UI
		Clear
		$Host.UI.RawUI.WindowTitle = $StartingWindowTitle
		
		# Remove Global Variables
		Get-Variable -Scope Global | Select -ExpandProperty Name |
		Where-Object {$StartupVariables -notcontains $_} |
	    ForEach-Object {Remove-Variable -Name ($_) -Scope "Global" -Force}
		
		If ($Global:WindowsPatchingDefaults.NoTips -eq $true) {
			Show-WPMHeader -SubScripts $Subscripts -NoTips
		}
		ElseIf ($Global:WindowsPatchingDefaults.NoHeader -eq $false) {
			Show-WPMHeader -SubScripts $Subscripts
		}
		
		# Clear Errors
		$Error.Clear()
	
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
	Install-Patches
	Test-WSUSClient
	Get-PendingUpdates
	Get-FailedClients
#>

<# Dependencies
#>

<# To Do List
	
#>

<# Change Log
	1.0.0 - 04/27/2012
		Created
	1.0.1 - 05/10/2012
		Added condition to check if Show-WPMHeader is loaded before loading it.
		Added Subscripts to Show-WPMHeader call
	1.0.2 - 05/14/2012
		Switched to Show-WPMHeader 1.0.2
	1.0.3 - 10/22/2012
		Switched to Show-WPMHeader 1.0.3
#>

#endregion Notes
