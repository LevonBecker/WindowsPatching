#requires –version 2.0

Function Invoke-PSExec {
	Param (
		[parameter(Position=0,Mandatory=$true)][string]$ComputerName,
		[parameter(Mandatory=$true)][string]$Assets,
		[parameter(Mandatory=$true)][string]$RemoteCommand,
		[parameter(Mandatory=$false)][int]$Timeout = '300'
		
	)
	# VARIABLES
	[string]$Notes = ''
	[boolean]$Success = $false
	[datetime]$SubStartTime = Get-Date
	[string]$ComputerName = $ComputerName.ToUpper()
	
#	$ExitCode = $null
	[string]$ExitCodeDescription = 'Unknown'
	[string]$PsExec = "$Assets\PsExec.exe"
	
	# REMOVE EXISTING OUTPUT PSOBJECT	
	If ($Global:InvokePSExec) {
		Remove-Variable InvokePSExec -Scope "Global"
	}
	
	#region Tasks
	
		# BUILD ARGUMENT LIST STRING
		[string]$ArgumentList = ' -accepteula -s -h -n ' + $Timeout + ' \\' + $ComputerName + ' ' + $RemoteCommand
		
		# RUN PSEXEC
		[int]$LoopCount = '0'
		Do {
			$LoopCount++
			Try {
				$PSExecProcess = Start-Process -FilePath $PsExec -ArgumentList $ArgumentList -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
				[boolean]$InvokePSExecError = $false
			}
			Catch {
				[boolean]$InvokePSExecError = $true
				Sleep -Seconds 1
			}
		}
		Until (($InvokePSExecError -eq $false) -or ($LoopCount -gt 10))
		
#		If ($LoopCount -gt 10) {
#			[boolean]$InvokePSExecError = $true
#		}
		
		If ($InvokePSExecError -eq $false) {
			# CAPTURE EXIT CODE
			[int]$ExitCode = $PSExecProcess.ExitCode
			
			# DETERMINE SUCCESS
			If ($ExitCode -eq '0') {
				[boolean]$Success = $true
			}
		
			# EXITCODE CROSSREFERENCE HASH (Library)
			Get-ExitCodeDescription -ExitCode $ExitCode
			If (($Global:GetExitCodeDescription.Success) -eq $true) {
				[string]$ExitCodeDescription = $Global:GetExitCodeDescription.Description
			}
			Else {
				[string]$ExitCodeDescription = 'Unknown'
			}
			
		} # PSEXEC ran without errors
		Else {
			[string]$ExitCode = 'ERROR'
			[string]$ExitCodeDescription = "PSEXEC COULD NOT RUN AFTER $LoopCount TRIES"
		}
		
	#endregion Tasks
	
	Get-Runtime -StartTime $SubStartTime
	
	# Create Results Custom PS Object
	$Global:InvokePSExec = New-Object -TypeName PSObject -Property @{
		ComputerName = $ComputerName
		Success = $Success
		Notes = $Notes
		Starttime = $SubStartTime
		Endtime = $Global:GetRunTime.Endtime
		Runtime = $Global:GetRunTime.Runtime
		ExitCode = $ExitCode
		PSExecProcess = $PSExecProcess
		ExitCodeDesc = $ExitCodeDescription
		LoopCount = $LoopCount
	}
}

#region Notes

<# Description
	Run commands on remote computer using PSExec.exe
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Install-Patches
	Test-WSUSClient
#>

<# Dependencies
	Get-Runtime
	Get-ExitCodeDescription
#>

<# Change Log
1.0.0 - 02/08/2012
	Created
1.0.1 - 02/08/2012
	Removed the SubFunction (Didn't give me -ErrorAction or -ErrorVariable option like I hoped)
	Removed Try/Catch (Three errors come out and it stops at the first before it finishes)
	Added TimeOut parameter
	Renamed $commands to $RemoteCommand
1.0.2 - 02/09/2012
	Changing to Start-Process instead of dot sourcing
1.0.3 - 02/09/2012
	Added ExitCode output
	Added -WindowStyle Hidden to Start-Process
	Changed to capture the who process output and included it in subscript output
1.0.4 - 02/10/2012
	Added Hash Table for exitcode descriptions
	Added ExitCodeDesc to output
	Changed -i to -h
1.0.5 - 02/10/2012
	Added Try/Catch
1.0.6 - 04/20/2012
	Changed parameter names
1.0.7
1.0.8
1.0.9 - 12/13/2012
	Changed Exitcode variable from string to integer to fix Hash Table lookup failure.
1.0.9 - 12/14/2012
	Removed cross reference table for getting the exitcode description and moved it to
		a subscript named Get-ExitCodeDescription that has all the Windows System
		Error Codes and not just a few I hand picked.
1.0.9 - 12/20/2012
	Fixed missing  from Get-ExitCodeDescription dot sourcing
1.1.0 - 01/04/2013
	Removed -SubScript parameter from all subfunction calls.
	Removed dot sourcing subscripts because all are loaded when the module is imported now.
#>

<# Sources
	Windows System Error Codes
		http://www.symantec.com/connect/articles/windows-ComputerName-error-codes-exit-codes-description
#>

#endregion Notes
