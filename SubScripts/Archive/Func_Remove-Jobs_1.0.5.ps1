#requires –version 2.0

Function Remove-Jobs {
	Param (
		[parameter(Position=0,Mandatory=$true)][string]$JobLogFullName,
		[parameter(Mandatory=$false)][int]$Timeout = '400' # 2 minutes = 120 seconds (300 Milliseconds x 400 (Loopcount) = 120000 Milliseconds)
	)
	# REMOVE STOPPED JobS AND OUTPUT Job DATA TO JobLOG
	[array]$Jobs = Get-Job
	
	If (($Jobs.Count) -ge 1) {
		Foreach ($Job in $Jobs) {
			[string]$JobName = $Job.Name
			[string]$JobState = $Job.State
			[string]$datetime = Get-Date -Format g
			
			If ($JobState -ne 'Running') {
				If ($Job.HasMoreData -eq $true) {
					# Out-String needed to capture all the output
					[array]$Jobdata = Receive-Job -Id $Job.Id -Keep -ErrorAction Continue 2>&1 | Out-String 
				}
				Else {
					[string]$Jobdata = 'NO Job DATA FOUND'
				}
				# WRITE TO Job LOG - IF ERROR WAIT AND TRY AGAIN
				[int]$loopcount = '0'
				[boolean]$errorfree = $false
				DO {
					$loopcount++
					[boolean]$errorfree = $false
					$logdata = @(
						'****************************************',
						"Job:         $JobName",
						"State:       $JobState",
						"Time:        $datetime",
						"Log Tries:   $loopcount",
						' ',
						'JobDATA',
						'----------------------------------------',
						' ',
						"$Jobdata"
						' ',
						'----------------------------------------'
					)

					Try {
						Add-Content -Path $JobLogFullName -Encoding Ascii -Value $logdata -ErrorAction Stop
						[boolean]$errorfree = $true
					}
					# IF FILE BEING ACCESSED BY ANOTHER SCRIPT CATCH THE TERMINATING ERROR
					Catch [System.IO.IOException] {
						[boolean]$errorfree = $false
						Sleep -Milliseconds 300
					}
					Catch {
						[boolean]$errorfree = $false
						Sleep -Milliseconds 300
					}
				}
				Until (($errorfree -eq $true) -or ($loopcount -ge $Timeout))
				Remove-Job -Id $Job.Id -Force
			}
		} # FOREACH LOOP
	} # IF THERE ARE JOBS
} # FUNCTION

#region Notes

<# Description
	Function to remove finished background Jobs. Used with Windows-Patching.ps1 script.
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Func_Watch-Jobs
	Func_Run-Patching
	Check-WSUSClients
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
#>

#endregion Notes
