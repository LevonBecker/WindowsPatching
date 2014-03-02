#requires –version 2.0

Function Get-VmTools {
	Param (
		[parameter(Position=0,Mandatory=$true)][string]$ComputerName,
		[parameter(Mandatory=$true)][string]$SubScripts, 
		[parameter(Mandatory=$false)][switch]$StayConnected,
		[parameter(Mandatory=$true)][string]$vCenter,
		[parameter(Mandatory=$false)][boolean]$UseAltViCredsBool = $false,
		[parameter(Mandatory=$false)]$ViCreds
	)
	# Variables
	[string]$Notes = ''
	[boolean]$Success = $false
	[datetime]$SubStartTime = Get-Date
	[string]$ComputerName = $ComputerName.ToUpper()
	
	$GetVM = $null
	$VmView = $null
	[string]$OSVersion = 'Unknown'
	[string]$GuestFamily = 'Unknown'
	[string]$ToolsStatus = 'Unknown'
	[string]$WindowsGuest = 'Unknown'
	[string]$GuestToolsVersion = 'Unknown'
	[string]$VmIP = 'Unknown'
	[boolean]$VmFound = $false
	
	. "$SubScripts\Func_Connect-ViHost_1.0.7.ps1"
	. "$SubScripts\Func_Disconnect-ViHost_1.0.1.ps1"
	. "$SubScripts\Func_Get-Runtime_1.0.3.ps1"
	
	If ($Global:GetVmTools) {
			Remove-Variable GetVmTools -Scope "Global"
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
		
		If ($Global:ConnectViHost.VIConnect -eq $true) {
			Try {
				$GetVM = Get-VM -Name $ComputerName -ErrorAction Stop
				[boolean]$VmFound = $true
			}
			Catch [System.Exception] {
				[string]$Notes += 'VM Not Found '
				[boolean]$VmFound = $false
			}
			If ($VmFound -eq $true) {
				$VmView = Get-View -VIObject $GetVM
				[string]$OSVersion = $VmView.Guest.GuestFullName
				If (($OSVersion | Select-String -Pattern ',') -ne $null) {
					[string]$OSVersion = $OSVersion.Replace(',', '')
				}
				If (($OSVersion | Select-String -Pattern '(R)') -ne $null) {
					[string]$OSVersion = $OSVersion.Replace('(R)', '') 
				}
				[string]$GuestFamily = $VmView.Guest.GuestFamily
				[string]$ToolsStatus = $VmView.Guest.ToolsStatus
				$GuestToolsVersion = $VmView.Guest.ToolsVersion
				$VmIP = $VmView.Guest.IpAddress
				# Get Connected Datastore ID LIST
				[array]$dsids = $GetVM.DatastoreIdList
				# Cross reference Datastore ID List to get Names
				$vmdatastores = $null
				Foreach ($dsid in $dsids) {
					[array]$vmdatastores += Get-Datastore -Id $dsid | Select -ExpandProperty Name
				}
				
				If ($GuestFamily -eq 'windowsGuest') {
					[boolean]$WindowsGuest = $true
				}
				Else {
					[boolean]$WindowsGuest = $false
				}
					
				If ($ToolsStatus -eq 'ToolsOK') {
					[boolean]$VmToolsOK = $true
					[string]$Notes += 'Tools OK '
				}
				ElseIf ($ToolsStatus -eq 'toolsOld') {
					[boolean]$VmToolsOK = $false
					[string]$Notes += 'Tools OLD '
				}
				Else {
					[string]$Notes += 'Tools Status Unknown '
				}
				[boolean]$Success = $true
			}
		}
		Else {
			[string]$Notes += 'ViHost Connection Failed '
		}
		If ($StayConnected.IsPresent -eq $false) {
			Disconnect-VIHost	
		}
		
	#endregion Task
	
	Get-Runtime -StartTime $SubStartTime
	
	# Create Results Custom PS Object
	$Global:GetVmTools = New-Object -TypeName PSObject -Property @{
		ComputerName = $ComputerName
		Notes = $Notes
		Success = $Success
		Starttime = $SubStartTime
		Endtime = $Global:GetRunTime.Endtime
		Runtime = $Global:GetRunTime.Runtime
		vCenter = $vCenter
		ViConnect = $Global:ConnectViHost.VIConnect
		VmFound = $VmFound
		OSVersion = $OSVersion
		VMIP = $VmIP
		GuestFamily = $GuestFamily
		ToolsStatus = $ToolsStatus
		WindowsGuest = $WindowsGuest
		VmToolsOK = $VmToolsOK
		GuestToolsVersion = $GuestToolsVersion
		VmDatastores = $vmdatastores
	}
}
#region Notes

<# Description
	Function to pull the network adapter IP Configuration of a remote ComputerName. 
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Func_Run-Patching
#>

<# Dependencies
	Func_Get-Runtime
	Func_Connect-ViHost
	Func_Disconnect-ViHost
#>

<# Change Log
	1.0.0 - 02/15/2011 (WIP)
		Created
	1.0.1 - 04/22/2011 (WIP)
		Started adding Try/Catch and new PSObject output method
	1.0.2 - 04/29/2011 (Stable)
		Split off PSSnapin, connect-Viserver etc. to two sub scripts
		ConntectTo-VIHost and DiscconectForm-VIHost
		Changed to PSObject output
		Added Try/Catch
	1.0.3 - 05/05/2011
		Added Runtime piece
	1.0.4 = 05/06/2011
		Added Else connection failed for If condition viconnect -eq true
		Removed $viconnect and used variable $Global:ConnectViHost.VIConnect instead
	1.0.5 - 10/02/2011
		Added GuestToolsVersion Output
	1.0.6 - 10/05/2011
		Added VM IP Address to output
	1.0.7 - 11/10/2011
		Added more parameter settings
		Added $UseAltViCredsBool and $ViCreds
	1.0.8 - 11/11/2011
		Changed to use Func_Connect-ViHost_1.0.7.ps1
#>

#endregion Notes
