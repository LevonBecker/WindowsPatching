#requires –version 2.0

Function Show-WindowsPatchingTip {
	
	#region Tips
	
		$a = {
			Write-Host 'TIP: ' -ForegroundColor Green -NoNewline
			Write-Host 'The ' -NoNewline
			Write-Host '-FileBrowser ' -ForegroundColor Yellow -NoNewline
			Write-host 'switch for Test-WSUSClient and Install-Patches will show a poppup window to chose your host list file from the local system.'
			Write-Host ''
			Write-Host '  EXAMPLE: ' -NoNewline
			Write-Host 'Install-Patches -FileBrowser' -ForegroundColor Yellow -NoNewline
			Write-Host ' <enter>'
			Write-Host ''
		}
		
#		$b = {
#			Write-Host 'TIP: ' -ForegroundColor Green -NoNewline
#			Write-Host 'The ' -NoNewline
#			Write-Host '-Groups ' -ForegroundColor Yellow -NoNewline
#			Write-host 'parameter for Get-WSUSClients can be used to input single or multiple WSUS Computer Groups.'
#			Write-Host ''
#			Write-Host '  EXAMPLE: ' -NoNewline
#			Write-Host 'Get-WSUSClients -Groups group01' -ForegroundColor Yellow -NoNewline
#			Write-Host ' <enter>'
#			Write-Host '           OR'
#			Write-Host '           Get-WSUSClients -Groups group01,group02,group03' -ForegroundColor Yellow -NoNewline
#			Write-Host ' <enter>'
#			Write-Host ''
#		}
		
		$c = {
			Write-Host 'TIP: ' -ForegroundColor Green -NoNewline
			Write-Host 'The ' -NoNewline
			Write-Host '-List ' -ForegroundColor Yellow -NoNewline
			Write-Host 'parameter for parent scripts can be used to input multiple hosts from the command line.'
			Write-Host ''
			Write-Host '  EXAMPLE: ' -NoNewline
			Write-Host 'Install-Patches -List server01,server02,server03' -ForegroundColor Yellow -NoNewline
			Write-Host ' <enter>'
			Write-Host ''
		}
		
		$d = {
			Write-Host 'TIP: ' -ForegroundColor Green -NoNewline
			Write-Host 'The ' -NoNewline
			Write-Host '-List ' -ForegroundColor Yellow -NoNewline
			Write-host 'parameter for parent scripts also excepts a PowerShell array variable to input multiple hosts from the command line.'
			Write-Host ''
			Write-Host '  EXAMPLE: ' -NoNewline
			Write-Host '$mylist = @("server01","server02","server03")' -ForegroundColor Yellow -NoNewline
			Write-Host ' <enter>'
			Write-Host '           Install-Patches -List $mylist' -ForegroundColor Yellow -NoNewline
			Write-Host ' <enter>'
			Write-Host ''
		}
		
		$e = {
			Write-Host 'TIP: ' -ForegroundColor Green -NoNewline
			Write-Host 'The ' -NoNewline
			Write-Host '-SkipPolicyUpdate ' -ForegroundColor Yellow -NoNewline
			Write-Host 'switch for Test-WSUSClient can be used to skip the GPO Update task.'
			Write-Host ''
			Write-Host '  EXAMPLE: ' -NoNewline
			Write-Host 'Test-WSUSClient -FileBrowser -SkipPolicyUpdate' -ForegroundColor Yellow -NoNewline
			Write-Host ' <enter>'
			Write-Host ''
		}
		
		$f = {
			Write-Host 'TIP: ' -ForegroundColor Green -NoNewline
			Write-Host 'The ' -NoNewline
			Write-Host '-SkipSettingsReset ' -ForegroundColor Yellow -NoNewline
			Write-Host 'switch for Test-WSUSClient can be used to skip the Windows Update Settings Reset task.'
			Write-Host ''
			Write-Host '  EXAMPLE: ' -NoNewline
			Write-Host 'Test-WSUSClient server01 -SkipSettingsReset' -ForegroundColor Yellow -NoNewline
			Write-Host ' <enter>'
			Write-Host ''
		}
		
		$g = {
			Write-Host 'TIP: ' -ForegroundColor Green -NoNewline
			Write-Host 'The ' -NoNewline
			Write-Host '-SkipOutGrid ' -ForegroundColor Yellow -NoNewline
			Write-Host 'switch for parent scripts can be used to skip the Out-GridView Results (Spreadsheet Poppup) at the end.'
			Write-Host ''
			Write-Host '  EXAMPLE: ' -NoNewline
			Write-Host 'Install-Patches -FileBrowser -SkipOutGrid' -ForegroundColor Yellow -NoNewline
			Write-Host ' <enter>'
			Write-Host ''
		}
		
		$h = {
			Write-Host 'TIP: ' -ForegroundColor Green -NoNewline
			Write-Host 'The ' -NoNewline
			Write-Host '-MaxJobs ' -ForegroundColor Yellow -NoNewline
			Write-Host 'parameter for Install-Patches, Test-WSUSClient and Get-PendingPatches can be used to throttle the background jobs. The default value is high so if system resources start to pose an issue use this to set a lower number of jobs that can run simultaneously.'
			Write-Host ''
			Write-Host '  EXAMPLE: ' -NoNewline
			Write-Host 'Install-Patches -FileBrowser -MaxJobs 50' -ForegroundColor Yellow -NoNewline
			Write-Host ' <enter>'
			Write-Host ''
		}
		
		$i = {
			Write-Host 'TIP: ' -ForegroundColor Green -NoNewline
			Write-Host 'The ' -NoNewline
			Write-Host '-WsusGroups ' -ForegroundColor Yellow -NoNewline
			Write-Host 'parameter for Install-Patches, Test-WSUSClient, Get-PendingPatches and Get-WSUSClients can be used to get a host list from one or many WSUS computer groups from the WSUS Server.'
			Write-Host ''
			Write-Host '  EXAMPLE: ' -NoNewline
			Write-Host 'Install-Patches -WsusGroups group01,group02' -ForegroundColor Yellow -NoNewline
			Write-Host ' <enter>'
			Write-Host ''
		}
		
		$j = {
			Write-Host 'TIP: ' -ForegroundColor Green -NoNewline
			Write-Host 'The ' -NoNewline
			Write-Host '-NoReboot ' -ForegroundColor Yellow -NoNewline
			Write-Host 'switch for Install-Patches can be used to skip all target computer restarts. If there are no pending reboots on the target system, it will install patches until a reboot is required or no more patches are needed.'
			Write-Host ''
			Write-Host '  EXAMPLE: ' -NoNewline
			Write-Host 'Install-Patches -WsusGroups group01,group02 -NoReboot' -ForegroundColor Yellow -NoNewline
			Write-Host ' <enter>'
			Write-Host ''
		}
		
	#endregion Tips
	
	#region Pick Random Tip
		
		# CREATE OBJECT OF SCRIPT BLOCKS
		$TipList = New-Object -TypeName PSObject -Property @{
			a = $a
#			b = $b
			c = $c
			d = $d
			e = $e
			f = $f
			g = $g
			h = $h
			i = $i
			j = $j
		}
		
		# CREATE ARRAY TO BE USED TO PICK A RANDOM TIP
		## Get-Random doesn't work on PSObject
		$PickList = @(
			"a",
#			"b",
			"c",
			"d",
			"e",
			"f",
			"g",
			"h",
			"i",
			"j"
		)
		
		# SELECT RANDOM FROM PICKLIST
		$Selected = Get-Random -InputObject $PickList
		
		# DISPLAY RANDOM SELECTED TIP SCRIPT BLOCK
		. $TipList.$Selected
	
	#region Pick Random Tip
}

#region Notes

<# Description
	Show random WindowsPatching Tips.
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Show-WPMHeader
#>

<# Dependencies
	Get-Runtime
#>

<# To Do List
	
#>

<# Change Log
1.0.0 - 05/03/2012
	Created
1.0.1 - 11/27/2012
	Removed FileName parameter
1.0.2 - 12/17/2012
	Change -SkipAllVmware tip to Get-WSUSClients tip $b
#>

#endregion Notes
