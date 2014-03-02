#requires –version 2.0

Function Get-Network {
	Param (
		[parameter(Position=0,Mandatory=$true)][string]$ComputerName,
		[parameter(Mandatory=$false)][switch]$StayConnected,
		[parameter(Mandatory=$false)][string]$vCenter,
		[parameter(Mandatory=$false)][boolean]$UseAltViCreds,
		[parameter(Mandatory=$false)]$ViCreds,
		[parameter(Mandatory=$false)][switch]$SkipVimQuery
	)
	# CLEAR VARIBLES
	[boolean]$Success = $false
	[string]$Notes = $null
	[datetime]$SubStartTime = Get-Date
	[string]$IPAddresses = 'Unknown'
	[string]$LookupMethod = 'All Failed'
	[boolean]$dnsquerysuccess = $false
	[boolean]$wmiquerysuccess = $false
	[boolean]$vimquerysuccess = $false
	
	If ($Global:GetNetwork) {
		Remove-Variable GetNetwork -Scope "Global"
	}
	
	#region Tasks
	
		#region Last Network Logon
		
			$data = @()
			$profiles = GWMI Win32_NetworkLoginProfile -ComputerName $ComputerName
			foreach ($profile in $profiles){
				$date = $profile.LastLogon
				if ($date -ne $null -and $date -ne "**************.******+***") {
					$row = "" | Select User,LogonTime
					$year = $date.SubString(0,4)
					$month = $date.SubString(4,2)
					$day = $date.SubString(6,2)
					$hour = $date.SubString(8,2)
					$min = $date.SubString(10,2)
					$sec = $date.Substring(12,2)
					$row.User = $Profile.Name
					$row.LogonTime = Get-Date -Date ($month + "/" + $day + "/" + $year + " " + $hour + ":" + $min + ":" + $sec)
					$data += $row
				}
			}
	
		#endregion Last Network Logon
	
		#region IP Addresses
	
			#region DNS Lookup
			
				$ErrorActionPreference = 'Stop'
				Try {
					[array]$dnsquery = [System.Net.Dns]::GetHostAddresses($ComputerName)
					[string]$IPAddresses = $dnsquery | Select -ExpandProperty IPAddressToString
					[boolean]$dnsquerysuccess = $true
					[boolean]$Success = $true
					[string]$LookupMethod = 'DNS'
					[string]$Notes += 'DNS Query Success '
				}
				Catch {
					[boolean]$dnsquerysuccess = $false
					[string]$Notes += 'DNS Query Failed '
				}
				$ErrorActionPreference = 'SilentlyContinue'
			
			#endregion DNS Lookup
			
			Try {
			[array]$WMINetworkAdapterConfiguration = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName $ComputerName -ErrorAction Stop -ErrorVariable WMIError
			[boolean]$WMIConnected = $true
			}
			Catch {
				[boolean]$WMIConnected = $false
				$Notes = 'ERROR: WMI Failed - '
#				If ($WMIError -like "*The RPC server is unavailable*") {
#					[string]$Notes += 'The RPC server is unavailable'
#				}
			}
			
			If ($WMIConnected -eq $true) {
				[int]$AdapterCount = $WMINetworkAdapterConfiguration.Count
				Foreach ($NetworkAdapter in $WMINetworkAdapterConfiguration) {
					$Description = $NetworkAdapter.Description
					[Boolean]$DHCPEnabled = $NetworkAdapter.DHCPEnabled
					[string]$IPAddresses = $NetworkAdapter | Select-Object -ExpandProperty IPAddress
					[string]$IPSubnet = $NetworkAdapter | Select-Object -ExpandProperty IPSubnet
					[string]$DefaultIPGateway = $NetworkAdapter | Select-Object -ExpandProperty DefaultIPGateway
					[string]$PrimaryWINS = $NetworkAdapter.WINSPrimaryServer
					[string]$SecondaryWINS = $NetworkAdapter.WINSSecondaryServer
					[string]$PrimaryDNS = $NetworkAdapter.DNSServerSearchOrder[0]
					[string]$SecondaryDNS = $NetworkAdapter.DNSServerSearchOrder[1]
					[string]$MACAddress = $NetworkAdapter.MACAddress
					[string]$MTU = $NetworkAdapter.MTU
					
#					Foreach ($IPAddress in $NetworkAdapter.IPAddress) {
#						[string]$IPAddresses += $_ + ' '
#					}
#					Description                : HP Network Team #1
#					DHCPEnabled                : False
#					IPAddress                  : {10.227.16.10}
#					IPSubnet                   : {255.255.255.224}
#					DefaultIPGateway           : {10.227.16.1}
#					DNSServerSearchOrder       : {10.177.196.43, 10.11.22.44}
#					DNSDomainSuffixSearchOrder : 
#					WINSPrimaryServer          : 10.11.22.44
#					WINSSecondaryServer        : 10.177.196.43
				}
				
				
				
			
				$IPConfigObj = $WMINetworkAdapterConfiguration | Select -Property Description,DHCPEnabled,IPAddress,IPSubnet,DefaultIPGateway,DNSServerSearchOrder,DNSDomainSuffixSearchOrder,WINSPrimaryServer,WINSSecondaryServer
				If ($IPConfigObj) {
					[boolean]$Success = $true
					[string]$Notes += 'Completed '
					[string]$IPConfig = $IPConfigObj | Out-String
				}
			}
			
			#region WMI Query
			
				If ($dnsquerysuccess -eq $false) {
					$wmiquery = $null
					Try {
						[array]$wmiquery = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $ComputerName -ErrorAction Stop
						[string]$Notes += "WMI Query Success "
						[boolean]$wmiquerysuccess = $true
						[string]$LookupMethod = 'WMI'
						[boolean]$Success = $true
					}
					Catch {
						[boolean]$wmiquerysuccess = $false
					}
					If ($wmiquerysuccess -eq $true) {
						[Management.ManagementObject]$adapter = $wmiquery | Where-Object {$_.IPAddress -match "(\b([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\b)"}
						[string]$IPAddresses = $adapter.IPAddress
					}
					Else {
						[string]$IPAddresses = 'Unknown'
						[boolean]$wmiquerysuccess = $false
						[string]$Notes += 'WMI Query Failed '
					}
				}
				
			#endregion WMI Query
			
			#region vCenter Query
			
				If (($dnsquerysuccess -eq $false) -and ($wmiquerysuccess -eq $false) -and ($SkipVimQuery.IsPresent -eq $false)) {
					Get-VmGuestInfo -ComputerName $ComputerName -vCenter $vCenter -UseAltViCreds $UseAltViCreds -ViCreds $ViCreds -SubScripts $SubScripts
					If ($Global:GetVmGuestInfo.Success -eq $true) {
						[string]$IPAddresses = $Global:GetVmGuestInfo.VMIP
						[boolean]$vimquerysuccess = $true
						[string]$LookupMethod = 'VIM'
						[boolean]$Success = $true
						[string]$Notes += 'VIM Query Success '
					}
					Else {
						[boolean]$vimquerysuccess = $false
						[string]$Notes += 'VIM Query Failed '
					}
				}
				
			#endregion vCenter Query
		
		#endregion IP Addresses
		
		#region MAC Addresses
		
			$wmiquery = Get-WmiObject -Class Win32_NetworkAdapter
		
		#endregion MAC Addresses
	
	#endregion Tasks
	
	Get-Runtime -StartTime $SubStartTime
	
	# Create Results Custom PS Object
	$Global:GetNetwork = New-Object -TypeName PSObject -Property @{
		Hostname = $ComputerName
		Success = $Success
		Notes = $Notes
		Starttime = $SubStartTime
		Endtime = $Global:GetRunTime.Endtime
		Runtime = $Global:GetRunTime.Runtime
		LookupMethod = $LookupMethod
		IPAddresses = $IPAddresses
		MACAddresses = $MACAddresses
		PrimaryDNS = $PrimaryDNS
		SecondaryDNS = $SecondaryDNS
		PrimaryWINS = $PrimaryWINS
		SecondaryWINS = $SecondaryWINS
		IPSubnet = $IPSubnet
		DefaultIPGateway = $DefaultIPGateway
	}
}
#Description,
#DHCPEnabled,
#IPAddress,
#IPSubnet,
#DefaultIPGateway,
#DNSServerSearchOrder,
#DNSDomainSuffixSearchOrder,
#WINSPrimaryServer,
#WINSSecondaryServer
#region Notes


<# Description
	To get the IP Address from Hostname
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Func_Invoke-Patching
	Test-WSUSClient
	Get-HostInfo
#>

<# Dependencies
	Func_Get-Runtime
#>

<# Change Log
1.0.0 - 10/11/2011 
	Created.
1.0.1 - 11/10/2011
	Added more parameter settings
	Added $UseAltViCreds and $ViCreds
1.0.2 - 11/11/2011
	Changed to use Func_Connect-ViHost_1.0.7.ps1
	Changed to use Func_Get-VmGuestInfo_1.0.4.ps1
1.0.3 - 04/23/2012
	Moved Notes to bottom
	Renamed client to computername
	Changed StayConnected and SkipVimQuery to switch
1.0.4 - 05/03/2012
	Renames
	SkipVIMQuery changed to switch
1.0.5 - 05/08/2012
	Cleaned up code
1.0.6 - 12/14/2012
	Moved Get VMInfo dot source so it doesn't load if not needed.
#>

#endregion Notes
