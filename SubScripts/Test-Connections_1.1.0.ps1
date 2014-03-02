#requires –version 2.0

Function Test-Connections {
	Param (
		[parameter(Position=0,Mandatory=$false)][string]$ComputerName,
		[parameter(Mandatory=$false)][array]$List,
		[parameter(Mandatory=$false)][int]$MaxJobs = '25',
		[parameter(Mandatory=$true)][string]$ResultsTextFullName,
		[parameter(Mandatory=$true)][string]$JobLogFullName,
		[parameter(Mandatory=$false)][int]$TestTimeout = '60', # Seconds
		[parameter(Mandatory=$false)][int]$JobmonTimeout = '600', # Seconds
		[parameter(Mandatory=$true)][int]$TotalHosts,
		[parameter(Mandatory=$false)][int]$DashCount,
		[parameter(Mandatory=$false)][string]$ScriptTitle,
		[parameter(Mandatory=$false)][boolean]$UseAltPCCredsBool = $false,
		[parameter(Mandatory=$false)][string]$PCCreds,
		[parameter(Mandatory=$false)][string]$WinTitleInput
	)
	# VARIABLES
	[string]$Notes = ''
	[boolean]$Success = $false
	[datetime]$SubStartTime = Get-Date
	
	[Boolean]$AllFailed = $false
		
	# REMOVE EXISTING OUTPUT PSOBJECT	
	If ($Global:TestConnections) {
		Remove-Variable TestConnections -Scope "Global"
	}
	
	#region Tasks
		
		If ($ComputerName) {
			[array]$List = $ComputerName
		}
		
		If ($List) {
			# SEND LIST TO COMPUTERS TO TEST C$ ACCESS
			Write-Host "`r".padright(40,' ') -NoNewline
			Test-Permissions -List $List -MaxJobs $MaxJobs -TestTimeout $TestTimeout -JobmonTimeout $JobmonTimeout -JobLogFullName $JobLogFullName -WinTitleInput $Global:WinTitleInput
			
			If ($Global:TestPermissions.Success -eq $true) {

				# IF FAILURES THEN UPDATE FAILED LOGS 
				##(Seperate from next statements so logs are wrote no matter next conditions results)
				If ($Global:TestPermissions.FailedCount -gt '0') {
					$FailedCount = $Global:TestPermissions.FailedCount
					$FailedList = $Global:TestPermissions.FailedList
				}

				# IF ALL FAILED REMOVE RESULTS FILE UPDATE ALLFAILED VARIABLE
				If ($Global:TestPermissions.AllFailed -eq $true) {
					# REMOVE EMPTY RESULTS FILE
					If ((Test-Path -Path $ResultsTextFullName) -eq $true) {
						Remove-Item -Path $ResultsTextFullName -Force
					}
					[boolean]$Success = $false
					[Boolean]$AllFailed = $true
				}
				# IF PARTIAL PASSED THEN PROMPT, REMOVE AND CONTINUE
				ElseIf ($Global:TestPermissions.PartialPassed -eq $true) {
					Show-ScriptHeader -blanklines '1' -DashCount $DashCount -ScriptTitle $ScriptTitle
					Write-Host "`rSOME SYSTEMS PASSED PERMISSIONS TEST" -ForegroundColor Yellow -NoNewline
					Sleep -Seconds 2
					[boolean]$Success = $true
					
					$FailedCount = $Global:TestPermissions.FailedCount
					$FailedList = $Global:TestPermissions.FailedList
				}
				# IF ALL PASSED THEN UPDATE UI AND CONTINUE
				ElseIf ($Global:TestPermissions.AllPassed -eq $true) {
					Show-ScriptHeader -blanklines '1' -DashCount $DashCount -ScriptTitle $ScriptTitle
					Write-Host "`rALL SYSTEMS PASSED PERMISSIONS TEST" -ForegroundColor Green -NoNewline
					Sleep -Seconds 2
					[boolean]$Success = $true
				}
				Else {
					# REMOVE EMPTY RESULTS FILE
					If ((Test-Path -Path $ResultsTextFullName) -eq $true) {
						Remove-Item -Path $ResultsTextFullName -Force
					}
					Show-ScriptHeader -blanklines '1' -DashCount $DashCount -ScriptTitle $ScriptTitle
					Write-Host "`r".padright(40,' ') -NoNewline
					Write-Host "`rERROR: PERMISSION TEST FAILURE" -ForegroundColor White -BackgroundColor Red
					Write-Host ''
					Break
				}
				
				# CREATE PASSED LIST OUTPUT
				[array]$passedList = $Global:TestPermissions.PassedList
				
				# COPY PASSED COUNT TO OUTPUT
				[int]$passedcount = $Global:TestPermissions.PassedCount
				
			} # IF Test-Permissions Successful
			Else {
				[string]$Notes += 'Test-Permissions Function Failed '
			}
		} #/If Host not blank
		Else {
			[string]$Notes += 'Missing Hostname '
		}
		
	#endregion Tasks
	
	Get-Runtime -StartTime $SubStartTime
	
	# Create Results Custom PS Object
	$Global:TestConnections = New-Object -TypeName PSObject -Property @{
		Success = $Success
		Notes = $Notes
		Starttime = $SubStartTime
		Endtime = $Global:GetRuntime.Endtime
		Runtime = $Global:GetRuntime.Runtime
		PassedList = $passedList
		PassedCount = $passedcount
		FailedList = $FailedList
		FailedCount = $FailedCount
		AllFailed = $AllFailed
	}
}

#region Notes

<# Description
	Function to test connection access to a remote Windows system.
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
	Get-DriveSpace
	Restart-Hosts
	Get-HostInfo
#>

<# Dependencies
	Get-Runtime
	Test-Permissions
#>

<# Change Log
1.0.0 - 02/02/2012
	Created
1.0.0 - 02/04/2012
	Added TotalHosts parameter
	Added Write-Progress
1.0.1 - 04/20/2012
	Move Notes to end
	Renamed soem parameters
	Fixed strict var types that were string and supposed to be boolean
1.0.2 - 04/27/2012
	Changes to make work in Module and not have default values.
1.0.3 - 04/30/2012
	Added support for Alternate PC Credentials
1.0.4 - 05/08/2012
	Added WinTitleInput parameter to pass to Test-Permissions
1.0.5 - 05/15/2012
	Added FailedList and FailedCount to Output
1.0.7 - 08/06/2012
	Removed prompt for partial passed "Continue" because now listed in output.
1.0.8 - 12/04/2012
	Removed break for if all permissions test fail
	Added AllFailed output to have the parent script show the error and use 
		The resetUI script to reset the console.
1.0.9 - 12/14/2012
	Removed Add-HostFile function no longer used.
1.1.0 - 01/04/2013
	Removed -SubScript parameter from all subfunction calls.
	Removed dot sourcing subscripts because all are loaded when the module is imported now.
#>
<# TO DO
	1. Other testing sub functions can be added for various connection tests
		a. ping?
		b. vCenter PowerON?
		c. Port checks?
#>

#endregion Notes
