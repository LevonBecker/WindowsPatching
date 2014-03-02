#requires –version 2.0

Function Get-TimeZone {

	Param (
	[parameter(Position=0,Mandatory=$true)][string]$ComputerName
	)
	# CLEAR VARIBLES
	[boolean]$Success= $false
	[boolean]$WMISuccess = $false
	[string]$Notes = $null
	
	# REMOVE EXISTING OUTPUT PSOBJECT	
	If ($global:GetTimeZone) {
		Remove-Variable GetTimeZone -Scope "Global"
	}
	
	#region Tasks
	
		Try {
		$Object = Get-WMIObject -class Win32_TimeZone -ComputerName $ComputerName
			[boolean]$Success = $true
			[boolean]$WMISuccess = $true
		}
		Catch {
			[string]$Notes += 'ERROR: WMI Object failure '
		}
		
		If ($WMISuccess -eq $true) {
			$StandardName = $Object.StandardName
			$DaylightName = $Object.DaylightName
			$Description = $Object.Description
			
			If ($StandardName -match "Eastern Standard Time") {
				[string]$ShortForm = 'EST'
			}
			ElseIf ($StandardName -match "Pacific Standard Time") {
				[string]$ShortForm = 'PST'
			}
			ElseIf ($StandardName -match "US Mountain Standard Time") {
				[string]$ShortForm = 'MST'
			}
			ElseIf ($StandardName -match "Central Standard Time") {
				[string]$ShortForm = 'CST'
			}
			Else {
				[string]$ShortForm = ''
			}
		}
	
	#endregion Tasks
	
	# Create Results Custom PS Object
	$global:GetTimeZone = New-Object -TypeName PSObject -Property @{
		ComputerName = $ComputerName
		Success = $Success
		Notes = $Notes 
		StandardName = $StandardName
		DaylightName = $DaylightName
		Description = $Description
		ShortForm = $ShortForm
	}
}

#region Notes

<# Description
	Get local host time zone setting OS.
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Add-NFSDS
	Get-PendingUpdates
	Install-Patches
	Test-WSUSClient
#>

<# Dependencies
	Get-Runtime
#>

<# To Do List
	
#>

<# Change Log
1.0.0 - 05/08/2012
	Created
#>

#endregion Notes
