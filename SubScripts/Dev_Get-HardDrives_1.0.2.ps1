#requires –version 2.0

Function Get-HardDrives {
	Param (
		[parameter(Position=0,Mandatory=$true)][string]$ComputerName,
		[parameter(Mandatory=$false)][int]$MinFreeMB = '500'
	)
	# CLEAR VARIBLES
	[string]$Notes = ''
	[boolean]$Success = $false
	[datetime]$SubStartTime = Get-Date
	[string]$ComputerName = $ComputerName.ToUpper()

	[boolean]$WMIConnected = $false
	[boolean]$Passed = $false
	[string]$DeviceID = 'Unknown'
		
	If ($Global:GetHardDrives) {
		Remove-Variable GetHardDrives -Scope "Global"
	}
	
	Try {
		[array]$LogicalDisks = Get-WmiObject -ComputerName $ComputerName -Class Win32_LogicalDisk -ErrorAction Stop
#		[array]$DiskDrives = Get-WmiObject -ComputerName $ComputerName -Class Win32_DiskDrive -ErrorAction Stop
		[boolean]$WMIConnected = $true
	}
	Catch {
		[string]$Notes += 'WMI Query Failed '
		[boolean]$WMIConnected = $false
	}
	
	If ($WMIConnected -eq $true) {
	
		#region Strip to Only Hard Disks
		
			[int]$DriveCount = 0
			[array]$HardDrives = @()
			# REMOVE FLOPPY, USB, CDROM ETC AND COUNT TOTAL HARD DRIVES
			# DriveType 3 = Local Hard Disk
			# DriveType X = LUN
			Foreach ($Drive in $LogicalDisks) {
				If ($Drive.DriveType -eq '3') {
					$DriveCount++
					$HardDrives += $Drive
				}
			}
		
		#region Strip to Only Hard Disks
		
		#region C Drive
		
			[Management.ManagementObject]$SystemDrive = $HardDrives | Where-Object {$_.DeviceID -eq 'C:'}
			[int]$SystemDriveFree = "{0:N0}" -f ($SystemDrive.FreeSpace / 1MB) 
			[string]$DeviceID = $SystemDrive.DeviceID
			[int]$SystemDriveSize = "{0:N0}" -f ($SystemDrive.Size / 1MB)  
			If ($SystemDriveFree) {
				If ($SystemDriveFree -ge $MinFreeMB) {
					[boolean]$Passed = $true
					[string]$Notes += 'Greater than or equal to Minimum Space on disk '
				}
				Else {
					[string]$Notes += 'Less than Minimum Space on disk '
				}
			}
			Else {
				[string]$Notes += 'Error: Evaluating System Drive Space '
			}
		
		#region C Drive
		
		#region All Drives
			
			$AllHardDrives = $null
			Foreach ($Disk in $HardDrives) {
				$CapacityKB = $Disk.Size
				[string]$DeviceID = $Disk.DeviceID
				[int]$CapacityGB = ($CapacityKB / 1GB)
				[string]$AllHardDrives += '(' + $DeviceID + '\' + $CapacityGB.ToString() + 'GB' + ')  '
			}
		
		#endregion All Drives
	}
	
	#region Determine Results
	
		If ($WMIConnected -eq $true) {
			[boolean]$Success = $true
		}
		
	#endregion Determine Results
	
	Get-Runtime -StartTime $SubStartTime
	
	# Create Results Custom PS Object
	$Global:GetHardDrives = New-Object -TypeName PSObject -Property @{
		ComputerName = $ComputerName
		Success = $Success
		Starttime = $SubStartTime
		Endtime = $Global:GetRunTime.Endtime
		Runtime = $Global:GetRunTime.Runtime
		Notes = $Notes
		WMIConnected = $WMIConnected
		SystemDriveSize = $SystemDriveSize
		MinFreeMB = $MinFreeMB
		SystemDriveFree = $SystemDriveFree
		Passed = $Passed
		DriveCount = $DriveCount
		AllHardDrives = $AllHardDrives
		
	}
}

#region Notes

<# Description
	Function to check hard disk space on remote ComputerName for minimum amount.
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Func_Run-Patching
	Get-HostInfo
#>

<# Dependencies
Func_Get-Runtime
#>

<# Change Log
	1.0.0 - 02/15/2011 (Beta)
		Created
	1.0.1 - 05/05/2011
		Converted results to PSObject output.
		Set default on minfree varible instead of condition statement doing it.
		Set parameter and other variable to specific case
		Added better error handling with Try/Catch, spliting up commands and conditions
		Added Runtime info
	1.0.2 - 07/21/2011
		Changed $Passed = 'Unknown' to $Passed = $false default value to fix it so when 
		there is not enough space it we have False as the value as intended.
#>

<# To Do List
#>

<# Sources
#>

#endregion Notes
