#requires –version 2.0

Function Remove-Jobs {
	Param (
		[parameter(Position=0,Mandatory=$false)][string]$JobLogFullName,
		[parameter(Mandatory=$false)][int]$Timeout = '400', # 2 minutes = 120 seconds (300 Milliseconds x 400 (Loopcount) = 120000 Milliseconds)
		[parameter(Mandatory=$false)][switch]$SkipJobLog
	)
	# REMOVE STOPPED JobS AND OUTPUT Job DATA TO JobLOG
	[array]$Jobs = Get-Job
	
	If (($Jobs.Count) -ge 1) {
		Foreach ($Job in $Jobs) {
			[string]$JobName = $Job.Name
			[string]$JobState = $Job.State
			[string]$DateTime = Get-Date -Format g
			
			If ($JobState -ne 'Running') {
				If ($Job.HasMoreData -eq $true) {
					# Out-String needed to capture all the output
					[array]$Jobdata = Receive-Job -Id $Job.Id -Keep -ErrorAction Continue 2>&1 | Out-String 
				}
				Else {
					[string]$Jobdata = 'NO Job DATA FOUND'
				}
				If (($SkipJobLog.IsPresent -ne $true) -and ($JobLogFullName -ne $null)) {
					# WRITE TO Job LOG - IF ERROR WAIT AND TRY AGAIN
					[int]$LoopCount = '0'
					[boolean]$ErrorFree = $false
					DO {
						$LoopCount++
						[boolean]$ErrorFree = $false
						$LogData = @(
							'****************************************',
							"Job:         $JobName",
							"State:       $JobState",
							"Time:        $DateTime",
							"Log Tries:   $LoopCount",
							' ',
							'JobDATA',
							'----------------------------------------',
							' ',
							"$Jobdata"
							' ',
							'----------------------------------------'
						)

						Try {
							Add-Content -Path $JobLogFullName -Encoding Ascii -Value $LogData -ErrorAction Stop
							[boolean]$ErrorFree = $true
						}
						# IF FILE BEING ACCESSED BY ANOTHER SCRIPT CATCH THE TERMINATING ERROR
						Catch [System.IO.IOException] {
							[boolean]$ErrorFree = $false
							Sleep -Milliseconds 300
						}
						Catch {
							[boolean]$ErrorFree = $false
							Sleep -Milliseconds 300
						}
					}
					Until (($ErrorFree -eq $true) -or ($LoopCount -ge $Timeout))
				}
				Remove-Job -Id $Job.Id -Force
			}
		} # FOREACH LOOP
	} # IF THERE ARE JOBS
} # FUNCTION

#region Notes

<# Description
	Function to remove finished background Jobs and log results.
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Watch-Jobs
	Test-WSUSClients
	Install-Patches
	Get-PendingUpdates
	Get-DriveSpace
#>

<# Dependencies
#>

<# Change Log
1.0.0 - 02/15/2011
	Created
1.0.1 - 03/21/2011
	Changed Parameter syntax
1.0.2 - 04/04/2011
	Changed Write-Output/Out-File to ADD-Content cmdlet
1.0.3 - 02/02/2012
	Added Latest Info section
	Added advanced parameter settings
	Removed Add-Content that had $Jobdata (not used anymore)
1.0.3 - 02/03/2012
	Completely re-wrote
	Removed Switch and added Foreach loop
	Added error handling for if the Job log is being accessed by another when it
	tries to access it.
	Consolidated the strings to add to the JobLog to one variable so less access time 
	and easier with Try/Catch
	Added parameter settings
	Set $JobLog as Mandatory
	Added Timeout parameter for flexability
1.0.4 - 05/03/2012
	Tons of renames to fit new standard and work with in module.
1.0.5 - 05/08/2012
	Added some test logic at start to check if there are jobs before trying anything.
1.0.6 - 11/08/2012
	Added SkipJobLog parameter switch
#>

#endregion Notes
