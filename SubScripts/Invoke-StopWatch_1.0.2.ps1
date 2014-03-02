#requires –version 2.0

Function Add-StopWatch {
	$Global:StopWatch = New-Object System.Diagnostics.StopWatch
}

Function Show-Stopwatch {
	# Display stopwatch Elaped time
	$ts = $Global:StopWatch.Elapsed
	$timer = [System.String]::Format("{0:00}:{1:00}:{2:00}", $ts.Hours, $ts.Minutes, $ts.Seconds)
	Write-Host "`rRUNTIME: " -ForegroundColor Green -NoNewline 
	Write-Host $timer -NoNewline
}

Function Start-Stopwatch {
  	$Global:StopWatch.Start()
}

Function Stop-Stopwatch {
  	$Global:StopWatch.Stop()
}

#region Notes

<# Description
	Stopwatch object to be displayed during processes to the console to 
	indicate progress.
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
#>

<# Dependencies
#>

<#
1.0.0 - 04/06/2011
	Created
1.0.1 - 05/1/2012
	No changes, just mass version upgrade cause this one for building Windows
	Patching module.
	Besides changing the filename.
1.0.2 - 12/14/2012
	Changed StopWatch variable to Global.
#>

#endregion Notes
