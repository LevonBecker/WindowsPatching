#requires –version 2.0

Function Get-VmGuestInfo {
	Param (
		[parameter(Position=0,Mandatory=$true)][string]$ComputerName,
		[parameter(Mandatory=$true)][string]$SubScripts,
		[parameter(Mandatory=$false)][switch]$StayConnected,
		[parameter(Mandatory=$true)][string]$vCenter,
		[parameter(Mandatory=$false)][string]$UseAltViCredsBool = $false,
		[parameter(Mandatory=$false)]$ViCreds
	)
	# Variables
	[string]$Notes = ''
	[boolean]$Success = $false
	[datetime]$SubStartTime = Get-Date
	[string]$ComputerName = $ComputerName.ToUpper()

	[boolean]$vmhostfound = $false
	[boolean]$vmfound = $false
	[string]$toolsstatus = 'Unknown'
	[string]$guestfamily = 'Unknown'
	[string]$winguest = 'Unknown'
	[string]$vmtoolsok = 'Unknown'
	[string]$vmtoolsversion = 'Unknown'
	[string]$vmip = 'Unknown'
	[string]$vmhost = 'Unknown'
	[string]$vmstatus = 'Unknown'
	[string]$powerstate = 'Unknown'
	[string]$CPUCount = 'Unknown'
	[string]$MemoryMB = 'Unknown'
	$vmview = $null
	$getvm = $null
	$vmdatastores = $null
	
	. "$SubScripts\Func_Get-Runtime_1.0.3.ps1"
	. "$SubScripts\Func_Connect-ViHost_1.0.7.ps1"
	. "$SubScripts\Func_Disconnect-ViHost_1.0.1.ps1"
	
	If ($global:GetVmGuestInfo) {
			Remove-Variable GetVmGuestInfo -Scope "Global"
	}
	
	#region Task
	
		If ($UseAltViCredsBool -eq $true) {
			If ($ViCreds) {
				Connect-VIHost -ViHost $vCenter -AltViCreds -ViCreds $ViCreds -SubScripts $SubScripts
			}
			Else {
				Connect-VIHost -ViHost $vCenter -AltViCreds -SubScripts $SubScripts
			}
		}
		Else {
			Connect-VIHost -ViHost $vCenter -SubScripts $SubScripts
		}
		
		If ($global:ConnectViHost.VIConnect -eq $true) {
			Try {
				$getvm = Get-VM -Name $ComputerName -ErrorAction Stop
				[boolean]$vmfound = $true
			}
			Catch [System.Exception] {
				$Notes += 'VM Not Found '
				[boolean]$vmfound = $false
			}
			Catch {
				$Notes += 'VM Not Found - General Exception '
				[boolean]$vmfound = $false
			}
			If ($vmfound -eq $true) {
				$vmview = Get-View -VIObject $getvm
				[string]$osversion = 'Unknown'
				[string]$osarch = 'Unknown'
				[string]$osversion = $vmview.Guest.GuestFullName
				If (($osversion | Select-String -Pattern ',') -ne $null) {
					# Remove any commas in the OS Version
					[string]$osversion = $osversion.Replace(',', '')
				}
				If (($osversion | Select-String -Pattern '®') -ne $null) {
					# Remove any commas in the OS Version
					[string]$osversion = $osversion.Replace('®', '')
				}
				If (($osversion | Select-String -Pattern '(R)') -ne $null) {
					# Remove Registered Trademark
					[string]$osversion = $osversion.Replace('(R)', '') 
				}
				If (($osversion | Select-String -Pattern '(32-bit)') -ne $null) {
					[string]$osversion = $osversion.Replace(' (32-bit)', '')
					[string]$osarch = '32-bit'
				}
				ElseIf (($osversion | Select-String -Pattern '(64-bit)') -ne $null) {
					[string]$osversion = $osversion.Replace(' (64-bit)', '')
					[string]$osarch = '64-bit'
				}
				Else {
					[string]$osarch = '32-bit'
				}
				[string]$guestfamily = $vmview.Guest.GuestFamily
				[string]$toolsstatus = $vmview.Guest.ToolsStatus
				[string]$vmtoolsversion = $vmview.Guest.ToolsVersion
				[string]$vmip = $vmview.Guest.IpAddress
				[string]$vmhost = $getvm.VMHost.Name
				[string]$vmNotes = $vmview.Config.Annotation
				
				# PARSE DOMAIN NAME FROM HOSTNAME
	#				$vmview = Get-View -VIObject $getvm
				[string]$guesthostname = $vmview.Guest.Hostname
				If (($guesthostname | Select-String -Pattern $ComputerName) -ne $null) {
					[string]$ComputerNamedot = $ComputerName + '.'
					[string]$hostdomain = $guesthostname -replace "$ComputerNamedot",""
				}
				Else {
					[string]$hostdomain = 'Unknown'
				}
				# Get Connected Datastore ID LIST
				[array]$dsids = $getvm.DatastoreIdList
				# Cross reference Datastore ID List to get Names
				Foreach ($dsid in $dsids) {
					[array]$vmdatastores += Get-Datastore -Id $dsid | Select -ExpandProperty Name
				}
				# FLATTEN ARRAY TO SINGLE LINE STRING
				$vmd = $null
				Foreach ($vmd in $vmdatastores) {
					[string]$vmds += $vmd + ' ' 
				}
				
	#				$vmdatastores = $getvm.VMHost.StorageInfo.FileSystemVolumeInfo | Select-Object -ExpandProperty 'Name'
				[string]$vmstatus = $vmview.OverallStatus
				[string]$powerstate = $getvm.PowerState
				[string]$CPUCount = $getvm.NumCpu
				[string]$MemoryMB = $getvm.MemoryMB
				
				If ($guestfamily -eq 'windowsGuest') {
					[boolean]$winguest = $true
				}
				Else {
					[boolean]$winguest = $false
				}
					
				If ($toolsstatus -eq 'ToolsOK') {
					[boolean]$vmtoolsok = $true
					[string]$Notes += 'Tools OK '
				}
				ElseIf ($toolsstatus -eq 'toolsOld') {
					[boolean]$vmtoolsok = $false
					[string]$Notes += 'Tools OLD '
				}
				Else {
					[string]$Notes += 'Tools Status Unknown '
				}
				
				# GET CURRENT VM HARDWARE VERSION
				[string]$vmhguestver = $vmview.Config.Version
				If ($vmhguestver -match 'vmx-04') {
					[string]$vmhguestversimple = '4'
				}
				ElseIf ($vmhguestver -match 'vmx-07') {
					[string]$vmhguestversimple = '7'
				}
				ElseIf ($vmhguestver -match 'vmx-08') {
					[string]$vmhguestversimple = '8'
				}
				Else {
					[string]$vmhguestversimple = 'Unknown'
					[string]$Notes += 'Vmhardware Guest Version not 4 7 or 8'
				}
			} # VM Found
		} # Connected to ViHost
		Else {
			[string]$Notes += 'ViHost Connection Failed '
		}
		
	#endregion Task
	
	# DISCONNECT FROM VIHOST IF STAYCONNECTED PARAMETER IS FALSE
	If ($StayConnected.IsPresent -eq $false) {
		Disconnect-VIHost	
	}

	# Determine Success
	If ($vmfound -eq $true) {
		[boolean]$Success = $true
	}
	
	Get-Runtime -StartTime $SubStartTime
	# Create Results Custom PS Object
	$global:GetVmGuestInfo = New-Object -TypeName PSObject -Property @{
		ComputerName = $ComputerName
		Notes = $Notes
		Success = $Success
		Starttime = $SubStartTime
		Endtime = $global:GetRunTime.Endtime
		Runtime = $global:GetRunTime.Runtime
		vCenter = $vCenter
		ViConnect = $global:ConnectViHost.VIConnect
		VmFound = $vmfound
		CompleteVmview = $vmview
		CompleteGetVM = $getvm
		OSVersion = $osversion
		VMIP = $vmip
		VmStatus = $vmstatus
		PowerState = $powerstate
		CPUCount = $CPUCount
		MemoryMB = $MemoryMB
		GuestFamily = $guestfamily
		ToolsStatus = $toolsstatus
		WindowsGuest = $winguest
		VmtoolsOK = $vmtoolsok
		VmHost = $vmhost
		VmDatastores = $vmds
		VmToolsVersion = $vmtoolsversion
		HostDomain = $hostdomain
		HardwareVersion = $vmhguestver
		OSArch = $osarch
		Annotation = $vmNotes
	}
}

#region Notes

<# Description
	Get virtual machine guest information using PowerCLI to query vCenter.
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Set-ESXSyslog
	Func_Get-HostIP
	Func_Get-OSVersion
	Func_Get-HostDomain
	Func_Get-HardwareInfo
	Get-HostInfo
#>

<# Dependencies
	Func_Get-Runtime
	Func_Connect-ViHost
	Func_Disconnect-ViHost
#>

<# Change Log
	1.0.0 - 10/02/2011 
		Created
	1.0.1 - 11/10/2011
		Added more parameter settings
		Added $UseAltViCreds and $ViCreds
	1.0.2 - 11/11/2011
		Changed to use Func_Connect-ViHost_1.0.7.ps1
	1.0.3 - 02/01/2012
		Added Host Domain gather
	1.0.4 - 04/23/2012
		Moved notes to bottom
		Changed client to computername
	1.0.5 - 05/03/2012
		Changed $UseAltViCreds to $UseAltViCredsBool
#>

#endregion Notes
