#requires –version 2.0

Function Invoke-PSService {
	Param (
		[parameter(Position=0,Mandatory=$true)][string]$ComputerName,
		[parameter(Mandatory=$true)][string]$Assets,
		[parameter(Mandatory=$true)][string]$RemoteCommand
	)
	# VARIABLES
	[string]$Notes = ''
	[boolean]$Success = $false
	[datetime]$SubStartTime = Get-Date
	[string]$ComputerName = $ComputerName.ToUpper()
	
	$exitcode = $null
	[string]$exitcodedesc = 'Unknown'
	[string]$PsService = "$Assets\PsService.exe"
	
	# REMOVE EXISTING OUTPUT PSOBJECT	
	If ($global:InvokePSService) {
		Remove-Variable InvokePSService -Scope "Global"
	}
	
	#region Tasks
	
		# BUILD ARGUMENT LIST STRING
		[string]$ArgumentList = ' -accepteula \\' + $ComputerName + ' ' + $RemoteCommand
		
		# RUN PS Service
		[int]$loopcount = 0
		Do {
			$loopcount++
			Try {
				$PsServiceProcess = Start-Process -FilePath $PsService -ArgumentList $ArgumentList -WindowStyle Hidden -Wait -PassThru -ErrorAction Stop
				[boolean]$RunPsServiceError = $false
			}
			Catch {
				[boolean]$RunPsServiceError = $true
				Sleep -Seconds 1
			}
		}
		Until (($RunPsServiceError -eq $false) -or ($loopcount -gt 10))
		
		If ($RunPsServiceError -eq $false) {
			# CAPTURE EXIT CODE
			[string]$exitcode = $PsServiceProcess.ExitCode
			
			# DETERMINE SUCCESS
			If ($exitcode -eq 0) {
				# THERE DOESN'T SEEM TO BE AN EXITCODE OTHER THAN 0
				[boolean]$Success = $true
			}
		} # PsService ran without errors
		Else {
			[string]$exitcode = 'ERROR'
			[string]$exitcodedesc = "PSSERVICE COULD NOT RUN AFTER $loopcount TRIES"
		}
		
	#endregion Tasks
	
	Get-Runtime -StartTime $SubStartTime
	
	# Create Results Custom PS Object
	$global:InvokePSService = New-Object -TypeName PSObject -Property @{
		ComputerName = $ComputerName
		Success = $Success
		Notes = $Notes
		Starttime = $SubStartTime
		Endtime = $global:GetRunTime.Endtime
		Runtime = $global:GetRunTime.Runtime
		ExitCode = $exitcode
		PsServiceProcess = $PsServiceProcess
		ExitCodeDesc = $exitcodedesc
		LoopCount = $loopcount
	}
}

#region Notes

<# Description
	Control Windows Services on remote Computer using PSService.exe
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Get-RegValue
#>

<# Dependencies
	Get-Runtime
#>

<# Change Log
1.0.0 - 04/20/2012
	Created
1.0.2 - 01/04/2013
	Removed -SubScript parameter from all subfunction calls.
	Removed dot sourcing subscripts because all are loaded when the module is imported now.
#>

<# Sources

#>

#endregion Notes
