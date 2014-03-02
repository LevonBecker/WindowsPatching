#requires –version 2.0

Function Out-ScriptLog-Header {
	Param (
		[parameter(Mandatory=$true)][string]$ScriptLogFullName,
		[parameter(Mandatory=$true)][string]$ScriptHost,
		[parameter(Mandatory=$true)][string]$UserDomain,
		[parameter(Mandatory=$true)][string]$UserName
	)
	$PSVersion = $PSVersionTable.PSVersion.ToString()
	$CLRVersion = ($PSVersionTable.CLRVersion.ToString()).Substring(0,3)
	
	$loginfo = @(
		'',
		"VERSION:         $ScriptVersion",
		"ACCOUNT:         $UserDomain\$UserName",
		"POWERSHELL:      $PSVersion",
		"CLRVersion:      $CLRVersion",
		"ADMIN HOST:      $ScriptHost",
		'',
		'MESSAGES:',
		'-----------------------------------------------------------------',
		''
	)
	Add-Content -Path $ScriptLogFullName -Encoding ASCII -Value $loginfo
}

Function Out-ScriptLog-Starttime {
	Param (
		[parameter(Mandatory=$true)]$StartTime,
		[parameter(Mandatory=$true)][string]$ScriptLogFullName
	)
	Add-Content -Path $ScriptLogFullName -Encoding ASCII -Value "SCRIPT STARTED:  $StartTime"
}

Function Out-ScriptLog-Error {
	Param (
		[parameter(Mandatory=$true)][string]$ComputerName,
		[parameter(Mandatory=$true)][string]$ScriptLogFullName,
		[parameter(Mandatory=$true)][string]$errortitle,
		[parameter(Mandatory=$false)][string]$Notes
	)
	$datetime = Get-Date -Format g
	$logdata = @(
		'',
		"[ERROR]          $errortitle",
		"HOST:            $ComputerName",
		"TIME:            $datetime",
		'',
		"NOTES:           $Notes"
	)
	Add-Content -Path $ScriptLogFullName -Encoding ASCII -Value $logdata
}

Function Out-ScriptLog-Errors {
	Param (
		[parameter(Position=0,Mandatory=$true)][string]$ScriptLogFullName,
		[parameter(Mandatory=$true)][string]$Errors
	)
	Foreach ($e in $Errors) {
		$logdata = $null
		$logdata += @($e | Out-String)
	}
	Add-Content -Path $ScriptLogFullName -Encoding ASCII -Value $logdata
}

Function Out-ScriptLog-JobTimeout {
	Param (
		[parameter(Mandatory=$true)][string]$ScriptLogFullName,
		[parameter(Mandatory=$true)][string]$JobmonNotes,
		[parameter(Mandatory=$true)]$EndTime,
		[parameter(Mandatory=$true)]$RunTime
	)
	$loginfo = @(
		'',
		'-----------------------------------------------------------------',
		'',
		"[JOB TIMEOUT]    $JobmonNotes",
		"SCRIPT ENDED:    $EndTime",
		"SCRIPT TIME:     $RunTime"
	)
	Add-Content -Path $ScriptLogFullName -Encoding ASCII -Value $loginfo
}

Function Out-ScriptLog-Footer {
	Param (
		[parameter(Mandatory=$true)][string]$ScriptLogFullName,
		[parameter(Mandatory=$true)]$EndTime,
		[parameter(Mandatory=$true)]$RunTime
	)
	$loginfo = @(
		'',
		'-----------------------------------------------------------------',
		'',
		"SCRIPT ENDED:    $EndTime",
		"SCRIPT TIME:     $RunTime"
	)
	Add-Content -Path $ScriptLogFullName -Encoding ASCII -Value $loginfo
}

#region Notes

<# Description
	Multiple Functions used for updating a script log
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Windows-Patching
	Check-WSUSClient
#>

<# Dependencies
#>

<# Change Log
	1.0.0 - 04/06/2011
		Created
	1.0.1 - 07/22/2011
		Added Out-ScriptLog-Error Function
	1.0.2 - 02/04/2012
		Added Parameter settings
		Removed Hostmethod parameter from Out-ScriptLog-Header
		Fixed $ScriptHost / $currenthost mismatch in Out-ScriptLog-Header
#>

#endregion Notes
