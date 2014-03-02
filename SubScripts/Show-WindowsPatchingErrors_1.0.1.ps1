#requires –version 2.0

Function Show-WindowsPatchingErrorMissingDefaults {

Write-Host ''
Write-Host 'ERROR: Please Run Set-WindowsPatchingDefaults First' -ForegroundColor White -BackgroundColor Red
Write-Host ''
Write-Host "This can be added to your user profile script to have it set automatically when launching PowerShell after Importing the WindowsPatching Module."
Write-Host ''
Write-Host "$ENV:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" -ForegroundColor Yellow
Write-Host ''
Write-Host 'EXAMPLE:' -ForegroundColor Yellow
Write-Host '# LOAD WINDOWSPATCHING MODULE' -ForegroundColor Green
Write-Host '$ModuleList = Get-Module -ListAvailable | Select -ExpandProperty Name'
Write-Host 'If ($ModuleList -contains 'WindowsPatching') {'
Write-Host '     Import-Module –Name WindowsPatching'
Write-Host '}'
Write-Host ''
Write-Host '# SET WINDOWS PATCHING DEFAULTS' -ForegroundColor Green
Write-Host 'If ((Get-Module | Select-Object -ExpandProperty Name | Out-String) -match "WindowsPatching") {'
Write-Host '     Set-WindowsPatchingDefaults -UpdateServerURL "https://wsus01.domain.com" -UpdateServer "wsus01.domain.com" -Quiet'
Write-Host '}'
Write-Host ''
Break

}

#region Notes

<# Description
	Display error and possible solutions for when a WindowsPatching CmdLet is
	used without first running Set-WindowsPatchingDefaults.
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
	Get-WSUSClients
	Get-WSUSFailedClients
	Move-WSUSClientToGroup
#>

<# Dependencies
	
#>

<# To Do List
	
#>

<# Change Log
1.0.0 - 05/03/2012
	Created
1.0.1 - 04/14/2013
	Renamed WPM to WindowsPatching
	Removed -vCenter in example
	Added -UpdateServer in example
#>

#endregion Notes
