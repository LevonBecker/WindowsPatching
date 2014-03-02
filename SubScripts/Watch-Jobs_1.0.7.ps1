#requires –version 2.0

Function Watch-Jobs {
	Param (
		[parameter(Mandatory=$true)][string]$JobLogFullName,
		[parameter(Mandatory=$false)][int]$Timeout = '1800',
		[parameter(Mandatory=$true)][string]$WinTitleInput,
		[parameter(Mandatory=$false)][string]$Activity = "Job Monitor"
	)

	#region Variables
	
		[string]$Notes = ''
		[boolean]$Success = $false
		[datetime]$SubStartTime = Get-Date
		
		If ($Global:WatchJobs) {
			Remove-Variable WatchJobs -Scope "Global"
		}
	
	#endregion Variables
	
	#region Tasks
	
#		Start-Stopwatch
		[int]$LoopCount = 0
		Do {
			$LoopCount++
			
			# GET JOB COUNT
			Get-JobCount
			[int]$JobsRunning = $Global:GetJobCount.JobsRunning
			# PROGRESS BAR
			Write-Progress -Activity $Activity -Status "JOBS RUNNING ($JobsRunning)"
			
			# REFRESH RUNTIME COUNTER ON UI
			Show-Stopwatch
						
			# UPDATE WINDOW TITLE WITH JOB COUNT
			Set-WinTitleJobCount -WinTitleInput $WinTitleInput -JobCount $Global:GetJobCount.JobsRunning
			
			# CLEANUP JOBS AND LOG OUTPUT
			Remove-Jobs -JobLogFullName $JobLogFullName

			# GET JOB COUNT 
			## Need at end to only loop once if the last of jobs are removed by cleanup-jobs
			Get-JobCount
			
			If ($Global:GetJobCount.JobCount -gt 0) {
				Sleep -Seconds 1
			}
		} 
		# DO UNTIL Timeout OR NO JOBS
		Until (($LoopCount -ge $Timeout) -or ($Global:GetJobCount.JobCount -eq 0))
		
		# CLOSE PROGRESS BAR
		Write-Progress -Activity $Activity -Status "COMPLETED" -Completed 
		
		# BAIL OUT OF JOBS IF OVER TIME LIMIT
		If ($LoopCount -ge $Timeout) {
			Stop-Job *
			Remove-Job *
			[boolean]$JobTimeout = $true
			[string]$Notes = '[JOB Timeout]    Jobs Running Over $Timeout Seconds'
		} #/If still jobs after Timeout
		Else {
			[boolean]$Success = $true
			[boolean]$JobTimeout = $false
		}
		Stop-Stopwatch
	
	#endregion Tasks
	
	Get-Runtime -StartTime $SubStartTime
	
	# Create Results Custom PS Object
	$Global:WatchJobs = New-Object -TypeName PSObject -Property @{
		Success = $Success
		Notes = $Notes
		Starttime = $SubStartTime
		Endtime = $Global:GetRunTime.Endtime
		Runtime = $Global:GetRunTime.Runtime
		JobTimeout = $JobTimeout
		Timeout = $Timeout
		JobLogFullName = $JobLogFullName
	}
}

#region Notes

<# Description
	Used to Monitor Background Jobs. 
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
	Move-ADComputers
	Get-HostInfo
#>

<# Dependencies
	Get-Runtime
	Cleanup_Jobs
	Get-JobCount
	Invoke-StopWatch
	Set-WinTitle
#>

<# Change Log
1.0.0 - 04/05/2011
	Created
1.0.1 - 02/02/2012
	Added Latest Info section
	Added advanced parameter settings
1.0.2 - 05/02/2012
	More renames to fit into module
1.0.3 - 05/08/2012
	Added Activity and Status Parameters to make this more universal and informative.
	Mainly so this can be used in Test-Permissions function
1.0.4 - 12/14/2012
	Removed Start-StopWatch and moved it to beginning of Parent script to get full Runtime and not
		just when the jobs are completely queued.
	Switched to MultiStopWatch 1.0.2
1.0.5 - 12/26/2012
	Switched to Remove-Jobs 1.0.6
1.0.6 - 12/28/2012
	Removed second hyphen from Set-WinTitle function
1.0.7 - 01/04/2013
	Removed -SubScript parameter from all subfunction calls.
	Removed dot sourcing subscripts because all are loaded when the module is imported now.
#>

#endregion Notes
