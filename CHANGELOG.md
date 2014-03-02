CHANGE LOG
---
**Windows Patching PowerShell Module**

[Module Info](http://www.bonusbits.com/main/Automation:Windows_Patching_PowerShell_Module)

***

**1.4.0** - 02/05/2013

* Removing all the Vmware pieces.  Moving them to another moduled I've named [Vmware-Tools](https://github.com/LevonBecker/Vmware-Tools)

**1.3.6** - 01/18/2013

* Added WsusGroup host list query parameter and logic to Test-WsusClient, Install-Patches and Get-PendingUpdates

**1.3.5** - 01/17/2013

* Cleaned up code

**1.3.4** - 01/14/2013

* Removed second hyphen from SubScript Function names
* Did some region cleanup and help/notes cleanup
* Moved Parent Scripts into a folder named ParentScripts
* Moved Shortcuts into a folder named Shortcuts
* Removed SubScript Dependency Checks from Parent Scripts
* Added Timezone to Log file datetime outputs

**1.3.3** - 01/04/2013

* Removed Func_ from SubScript Filenames
* Removed dot sourcing subscripts
* Removed $SubScripts parameter from SubScripts and Parent Scripts
* Load all SubScripts when module is imported
* Added Import-Module to parent script background jobs to work around file access issue if in the system folder
* Added Module Argument to skip showing the header. Used when loading Module in background job.
* Most if not all the Subscripts versions were revised for the changes.

**1.3.1** - 12/26/2012

* Switched to Install-Patches 2.7.7
* Switched to Get-WSUSClients 2.5.6
* Switched to Get-PendingUpdates **1.**1.0

**1.3.0** - 12/18/2012

* Switched to Get-WSUSClients **1.0.4
* Switched to Get-WSUSFailedClients **1.0.3
* Switched to Get-WSUSClients 2.5.5
* Switched to Install-Patches 2.7.6
* Switched to Get-PendingUpdates **1.0.9

**1.2.9** - 12/17/2012

* Switched to Install-Patches 2.7.5
* Switched to Test-WSUSClient 2.5.4
* Switched to Get-PendingUpdates **1.0.8
* Switched to Func_Test-Connections **1.0.9
* Switched to Func_Show-WPMHeader **1.0.4
* Switched to Func_Show-WPMTip **1.0.2
* Switched to Func_WindowsPatchingDefaults **1.0.5
* Switched to Get-WSUSClients **1.0.3
* Switched to Get-WSUSFailedClients **1.0.2
* Switched to Reset-WPMUI **1.0.4
* Added Func_Get-ExitCodeDescription **1.0.0

**1.2.8** - 12/14/2012

* Switched to Install-Patches 2.7.4
* Switched to Test-WSUSClient 2.5.3
* Switched to Func_Invoke-PSExec **1.0.9
* Switched to Func_Get-HostIP **1.0.6
* Switched to Func_Get-HostDomain **1.0.3
* Switched to Func_Test-Connections **1.0.9
* Switched to MultiFunc_StopWatch **1.0.2
* Removed all Vmware related tasks and moved to another module.
* Removed Func_Add-HostToLogFile
* Removed Func_Connect-ViHost
* Removed Func_Disconnect-ViHost
* Removed Func_Get-IPConfig
* Removed Func_Get-HardwareInfo
* Removed Func_Get-Vmtools
* Removed Func_Get-VmHardware
* Removed Func_Update-VmTools
* Removed Func_Update-VmHardware
* Removed Func_Send-VMPowerOff
* Removed Func_Send-VMPowerOn
* Removed Func_VmGuestInfo
* Removed MultiFunc_Out-ScriptLog

**1.2.7** - 12/13/2012

* Switched to Install-Patches 2.7.2
* Switched to Test-WSUSClient 2.5.2
* Removed Invoke-Patching

**1.2.6** - 12/04/2012

* Switched to Get-Pending **1.0.7
* Switched to Test-WSUSClient 2.5.1
* Switched to Install-Patches 2.7.1

**1.2.5** - 11/27/2012

* Switched to Get-Pending **1.0.6
* Switched to Invoke-Patching **1.5.2
* Switched to Test-WSUSClient 2.5.0
* Switched to Install-Patches 2.7.0
* Switched to Install-Patches **1.0.5 vbs
* Removed FileName parameter from Tips subscript

**1.2.4** - 11/09/2012

* Switched to Get-WSUSClients_**1.0.2
* Switched to Get-WSUSFailedClients_**1.0.1

**1.2.3** - 11/06/2012

* Added to Get-WSUSFailedClients_**1.0.0

**1.2.2** - 10/31/2012

* Added PoshWSUS nested module
* Added to Get-WSUSClients_**1.0.0

**1.2.1** - 10/22/2012

* Switched to Test-WSUSClient 2.4.9
* Switched to Install-Patches 2.6.9* 

**1.2.0** - 08/24/2012

* Switched to Get-WPCommand **1.0.1
* Switched to Invoke-Patching **1.5.1
* Switched to Test-WSUSClient 2.4.8
* Switched to Install-Patches 2.6.8

**1.1.9** - 08/13/2012

* Fixed missing output fields for failed systems.

**1.1.8** - 08/08/2012

* Switched to Test-WSUSClient 2.4.7
* Added Get-WPCommand **1.0.0

**1.1.7** - 08/06/2012

* Switched to Get-OSVersion **1.**1.0* 

**1.1.6** - 07/27/2012

* Switched to Test-WSUSClient 2.4.6
* Switched to Invoke-PSExec **1.0.8
* Switched to Install-Patches 2.6.6
* Switched to Invoke-Patching **1.5.0
* Switched to Update-VmTools **1.0.9* 

**1.1.5** - 07/27/2012

* Switched to Test-WSUSClient 2.4.5* 

**1.1.4** - 07/26/2012

* Switched to Install-Patches 2.5.6
* Switched to Invoke-Patching **1.4.9* 

**1.1.3** - 07/25/2012

* Switched to Test-WsusClient 2.4.4

**1.1.2** - 05/16/2012

* Cleaned up and added to help files for the primary CmdLets.
* Switched to Get-OSVersion **1.0.9
* Cleaned up and added to notes on subscripts.
* Changed Module Manifest to check for CLR 4.0 and not a specific build.

**1.1.1** - 05/15/2012

* Added Failed Access hosts to Results output
* Added Connect Success to Results output
* Changed Default Log and Results folder names
* Changed Default location for log folder
* Several CmdLet and SubScript improvements
* Renamed SearchDownloadInstall-WUA.vba to Install-Patches.vbs
* Renamed WUReset.cmd to Reset-WUAServices.cmd
* Renamed History files
* Renamed LatestPatch log to Temp
* Added Latest log that is the latest section from in the History log
* Moved around columns in results
* Added and removed items in the results

**1.1.1** - 05/14/2012

* Switched to Show-WPMHeader **1.0.2
* Switched to Show-WPMTip **1.0.2
* Added Get-PendingUpdates **1.0.0
* Added Func_Get-PendingPatches **1.0.0
* Fixed Alt Vi Creds prompt region end
* Switched to Set-WindowsPatchingDefault **1.0.3

**1.1.0** - 05/11/2012

* Fixed skip all vmware in Test-WSUSclient
* Fixed Alt VI Creds prompt in Test-WSUSClient and Install-Patches

**1.0.9** - 05/10/2012

* Renamed Reset-UI to Reset-WPMUI* 

**1.0.8** - 05/08/2012

* Added more tips to Show-WPMTips and moved to **1.0.1
* Added Logic for Skipping Vmware tasks in Test-WSUSClient
* Fixed Test-WSUSClient calling wrong version of Get-OSVersion
* Added ChangeLog.txt
* Added README.txt
* Added Get-TimeZone
* With the Get-TimeZone now the file names are set with the correct timezone of the script host.
* Fixed a few issues with Jobs Running WinTitle updates
* Added WinTitle Updates from Test-Permissions
* Adjusted Maxjobs and Timeouts to be more efficient
* Fixed issue in Remove-Jobs if now jobs were running
* Added short pause when a few background jobs have started to let the system catchup, after the initial 10 or 20 the script host runs better.
* Added section to remove WIP files if Job Loop Times out.

**1.0.7** - 05/07/2012

* Added Show-WPMTips **1.0.0
* Moved Show-WPMTips, Show-WPMHeader and Get-FileName to SubScripts folder
* Renamed the three above to start with Func_

**1.0.6** - 05/03/2012

* Released as Module

--- 
