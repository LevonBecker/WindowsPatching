#requires –version 2.0

Function Test-Permissions {
	Param (
		[parameter(Position=0,Mandatory=$false)][string]$ComputerName,
        [parameter(Mandatory=$false)][array]$List,
		[parameter(Mandatory=$false)][int]$MaxJobs = '25',
		[parameter(Mandatory=$true)][string]$SubScripts,
		[parameter(Mandatory=$true)][string]$JobLogFullName,
		[parameter(Mandatory=$false)][int]$TestTimeout = '60', # Seconds
		[parameter(Mandatory=$false)][int]$JobmonTimeout = '600', # Seconds
		[parameter(Mandatory=$false)][string]$WinTitle_Input
	)
	
	#region Variables
	
		[string]$Notes = ''
		[boolean]$Success = $false
		[datetime]$SubStartTime = Get-Date

		$FailedList = @()
		$PassedList = @()
		
		If ($Global:TestPermissions) {
			Remove-Variable TestPermissions -Scope "Global"
		}
	
	#endregion Variables
	
	#region Functions
	
		. "$SubScripts\Func_Get-Runtime_1.0.3.ps1"
		. "$SubScripts\Func_Get-JobCount_1.0.3.ps1"
		. "$SubScripts\MultiFunc_Set-WinTitle_1.0.5.ps1"
		
	#endregion Functions
	
	#region Tasks
		
		# STOP AND REMOVE ANY RUNNING JOBS
		Stop-Job *
		Remove-Job *
	
		# SHOULD SHOW ZERO JOBS RUNNING
		Get-JobCount 
		Set-WinTitle-JobCount -WinTitle_Input $Global:WinTitle_Input -jobcount $Global:GetJobCount.JobsRunning
	
		If ($ComputerName) {
			[string]$ComputerName = $ComputerName.ToUpper()
			[array]$List = $ComputerName
		}
		
		If ($List) {
			# Change Hostnames to Upper Case
			[array]$List = $List | ForEach-Object {$_.ToUpper()}
			# Remove Duplicates in Array
			[array]$List = $List | Select -Unique
			# Create empty Hashtable
			
			#region Job Loop
				
				[int]$hostcount = $List.Count
				[int]$i = '0'
				$Jobs = @{}
				[boolean]$FirstGroup = $false
				Foreach ($ComputerName in $List) {
					$taskprogress = [int][Math]::Ceiling((($i / $hostcount) * 100))
					# Progress Bar
					Write-Progress -Activity "CREATING CONNECTION TEST JOB FOR - ($ComputerName)" -PercentComplete $taskprogress -Status "OVERALL PROGRESS - ($taskprogress%)"

					#region Throttle Jobs
					
						# Loop Until Less Than Max Jobs Running
						Get-JobCount
						Set-WinTitle-JobCount -WinTitle_Input $Global:WinTitle_Input -jobcount $Global:GetJobCount.JobsRunning
						
						# PAUSE FOR A FEW AFTER THE FIRST 25 ARE QUEUED
						If (($Global:GetJobCount.JobsRunning -ge '10') -and ($FirstGroup -eq $false)) {
							Sleep -Seconds 5
							[boolean]$FirstGroup = $true
						}
						
						While ($Global:GetJobCount.JobsRunning -ge $MaxJobs) {
							Sleep -Milliseconds 500
							Get-JobCount
							Set-WinTitle-JobCount -WinTitle_Input $Global:WinTitle_Input -jobcount $Global:GetJobCount.JobsRunning
						}
					
					#endregion Throttle Jobs
					
					#region Background Job
					
						$Jobs.Add($ComputerName,(Start-Job -ScriptBlock {
							#region Job Variables

							# Set Varibles from Argument List
							$ComputerName = $args[0]
							$TestTimeout = $args[1]

							#endregion Job Variables

							#region Job Task 1
							
							# TEST C$ PATH FOR EACH HOST LISTED IN CURRENT FILE LIST
							$fullpath = $null
							[string]$fullpath = '\\' + $ComputerName + '\C$'
							[int]$loopcount = 0
							Do {
								$loopcount++
								[boolean]$unctestsuccess = $false
								[boolean]$unctest = $false
								Sleep -Seconds 1
								Try {
									$unctest = Test-Path -Path $fullpath -ErrorAction Stop
									[boolean]$unctestsuccess = $true
								}
								Catch {
									[boolean]$unctestsuccess = $false
									[boolean]$Success = $false
								}
								If ($unctestsuccess -eq $true) {
									If ($unctest -eq $true) {
										[boolean]$passed = $true
									}
									If ($unctest -eq $false) {
										[boolean]$passed = $false
#										[string]$Notes += "Failed to connect for $ComputerName, "
									}
								}
#								Else {
#									[string]$Notes += "Failed Test-Path Cmdlet for $ComputerName, "
#								}
							}
							Until (($unctestsuccess -eq $true) -or ($loopcount -ge $TestTimeout))
							
							# WRITE OUTPUT TO QUERY FROM RECEIVE-JOB ^Still needed?
							# Don't use Clear because it Wipes out UI Header
							Write-Output "PASSED: $passed"
							
							#endregion Job Task 1
							
						} -ArgumentList $ComputerName,$TestTimeout))
					
					#endregion Background Job
					
					$i++
				} #Foreach
				
				Get-JobCount 
				Set-WinTitle-JobCount -WinTitle_Input $Global:WinTitle_Input -jobcount $Global:GetJobCount.JobsRunning
				
			#endregion Job Loop
			
			#region Job Monitor Loop
			
				# Job Monitoring (Waiting for all to be Completed)
				[int]$loopcount = '0'
				Do {
					# Progress Bar
					Sleep -Seconds 1
					$loopcount++
					[int]$completedcount = '0'
					[int]$notcompletedcount = '0'
					# ^May have issues if the state doesn't auto update in the Hashtable
					# If that's the case maybe just pull Get-Job queries
					[array]$GetJobs = Get-Job
					$GetJobs | ForEach-Object {
						If ($_.State -eq 'Completed') {
							$completedcount++
						}
						Else {
							$notcompletedcount++
						}
					 }
					# PROGRESS BAR
					Write-Progress -Activity "CONNECTION TEST JOBS RUNNING" -Status "JOBS LEFT - $notcompletedcount"
					Get-JobCount 
					Set-WinTitle-JobCount -WinTitle_Input $Global:WinTitle_Input -jobcount $Global:GetJobCount.JobsRunning
				}
				Until (($notcompletedcount -eq 0) -or ($loopcount -ge $JobmonTimeout))
				Write-Progress -Activity "CONNECTION TEST JOBS RUNNING" -Status "COMPLETED" -Completed 
				
				# SHOULD BE ZERO UNLESS JOB MONITOR TIMED OUT
				Get-JobCount 
				Set-WinTitle-JobCount -WinTitle_Input $Global:WinTitle_Input -jobcount $Global:GetJobCount.JobsRunning
				
				If ($loopcount -ge $JobmonTimeout) {
					[string]$Notes += 'Some of the jobs did not complete. Loop bailed after timeout. '
				}
				[string]$Notes += 'Exited Loop '
			
			#endregion Job Monitor Loop
			
			#region Collect Job Output
			
				# CREATE HASH TABLE WITH JOB OUTPUT
				$JobData = @{}
				$Jobs.Keys | ForEach-Object {$JobData.Add(($_),($Jobs.$_ | Receive-Job -Keep))}
				$Jobs.Keys | ForEach-Object {$Jobs.$_ | Remove-Job}

				# CREATE AND POPULATE THE PASS AND FAIL LIST ARRAYS
				$JobData.Keys | ForEach-Object {
					If (($JobData.$_.Contains('PASSED: True')) -eq $true){
						$PassedList += @($_)
					} 
					Else {
						$FailedList += @($_)
					}
				}
			
			#endregion Collect Job Output
			
			#region Determine Results
			
				# Count up Pass and Fails
				[int]$FailedCount = $FailedList.Count
				[int]$PassedCount = $PassedList.Count
				[int]$TestCount = $List.Count
				If ($FailedCount -eq $TestCount) {
					[boolean]$AllFailed = $true
					[boolean]$AllPassed = $false
					[boolean]$PartialPassed = $false
					[boolean]$Success = $true
				}
				If ($PassedCount -eq $TestCount) {
					[boolean]$AllPassed = $true
					[boolean]$AllFailed = $false
					[boolean]$Success = $true
				}
				If (($PassedCount -gt 0) -and ($FailedCount -gt 0)) {
					[boolean]$PartialPassed = $true
					[boolean]$AllPassed = $false
					[boolean]$AllFailed = $false
					[boolean]$Success = $true
				}
				
			#endregion Determine Results
			
		} #IF List 
		Else {
			[string]$Notes += 'Missing Hostname '
		}

	#endregion Tasks
	
	Get-Runtime -StartTime $SubStartTime
	
	# Create Results Custom PS Object
	$Global:TestPermissions = New-Object -TypeName PSObject -Property @{
		Success = $Success
		Notes = $Notes
		Starttime = $SubStartTime
		Endtime = $Global:GetRunTime.Endtime
		Runtime = $Global:GetRunTime.Runtime
		HostList = $List
		PassedList = $PassedList
		PassedCount = $PassedCount
		FailedCount = $FailedCount
		TestCount = $TestCount
		FailedList = $FailedList
		AllPassed = $AllPassed
		AllFailed = $AllFailed
		PartialPassed = $PartialPassed
		JobData = $JobData
		Jobs = $Jobs
	}
}

#region Notes

<# Description
	Function to remote access permissions to a Windows system.
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Windows-Patching
	Test-Permissions
	Func_Test-Connections
#>

<# Dependencies
	Func_Get-Runtime
	Func_Cleanup_Jobs
	Func_Get-JobCount
#>

<# Change Log
	1.000 - 07/27/2011 
		Created.
	1.001 - 10/09/2011
		Changed Get-JobCount Variable
		Figured out how to create a Hash Table containing the job info crossed to the hosts!
	1.002 - 10/10/2011
		Building out capaturing data from Hash table to condition
	1.003 - 10/14/2001
		Added loop to the test incase the host wasn't accessable because of latency on network or Vmware
	1.004 - 11/01/2011
		Added allpassed and allfailed False if partialpassed
	1.005 - 11/04/2011
		Added HostList to output
	1.006 - 02/02/2012
		Added Timeout Parameter
		Changed $HostList to $List inside task section
		Set JobLogFullName parameter as mandatory
		Dropped $MaxJobs default to 25
		Added Testtimeout and JobsTimeout parameters and replaced in job loop
		Hardset several variable types i.e. [string]
		Added regions for code folding
		Changed $ComputerName parameter to $computer
		Change first part to check if missing host and feed $computer into $List
	1.0.7 - 04/20/2012
		Moved Notes to end
		Renamed files with cases
	1.0.9 - 05/02/2012
		More Renamed and adjustments to fit it in to Module.
		
#>

<# To Do List

#>

<# Sources

Microsoft Technet
	http://technet.microsoft.com/en-us/library/dd315369.aspx

#>

#endregion Notes
