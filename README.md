# Windows Patching PowerShell Module

## Purpose

A PowerShell module for patching Windows servers or desktops with WSUS as the Client Patch Source.

The PowerShell module can be used to patch hundreds or even thousands of Windows remote computers that are on a domain. 
The module patches them simultaneously unlike a lot that you will find out there. Meaning, you can patch 100 or 500 all at the same time. 
It really just depends on the resources available on the system the module is ran on, the environment resources and server services (What can be down at the same time).

The module does three main tasks:

1. Test WSUS Client settings on remote computers
2. Install Windows Patches on remote computers
3. Check for Pending Windows Updates on remote computers

These major tasks are executed with these CmdLets:

1. Test-WSUSClient
2. Install-Patches
3. Get-PendingUpdates

These CmdLets except a single host, typed out list of hosts or a file with a list of host names.

I used the Test-WSUSClient CmdLet to test hundreds of systems before the maintenance window to determine if they have the correct WSUS GPO settings in the registry and have sufficient local host and firewall permissions.

Then during the maintenance window I use the list of passed systems with the Install-Patches CmdLet to install the Windows patches, upgrade Vmware Tools and upgrade Vmware VM Hardware if needed during the patch window.

Before or after the maintenance window I use the Get-PendingUpdates CmdLet to check is there are pending patches needed.

I split the list into two groups and separate clustered or redundant services. Such as, splitting up domain controllers, clustered SQL servers, clustered terminal servers, etc.

## More Information 
[HowTo Use Windows Patching PowerShell Module](http://www.bonusbits.com/wiki/HowTo:Use_Windows_Patching_PowerShell_Module)

## Disclaimer
Use at own risk.
