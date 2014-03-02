# Windows Patching PowerShell Module

[HowTo Use](http://www.bonusbits.com/main/HowTo:Use_Windows_Patching_PowerShell_Module_to_Automate_Patching_with_WSUS_as_the_Client_Patch_Source)
[Module Info](http://www.bonusbits.com/main/Automation:Windows_Patching_PowerShell_Module)

## Setup Summary

1. PowerShell 2.0+
2. .NET 4.0+
3. PowerShell CLR set to run 4.0+
4. WSUS 3.x installed on script host for WSUS binaries (Doesn't have to be setup)
  + Only if using Get-WSUSClients, Get-WSUSFailedClients, Move-WSUSClientToGroup and -WsusGroup parameter
5. Set-ExecutionPolicy to Unrestricted
6. Create %USERPROFILE%\Documents\WindowsPowerShell\Modules Folder if needed
7. Download latest WindowsPatching Module
8. Extract Module folder to %USERPROFILE%\Documents\WindowsPowerShell\Modules\
9. Import-Module
10. Run Set-WindowsPatchingDefaults


## Optional 
Add code to PowerShell user profile script to Import and run Set-WindowsPatchingDefaults automatically when PowerShell is launched.

#### EXAMPLE


**$ENV:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1**

```powershell
# LOAD WINDOWSPATCHING MODULE
$ModuleList = Get-Module -ListAvailable | Select -ExpandProperty Name
If ($ModuleList -contains 'WindowsPatching') {
	Import-Module –Name WindowsPatching
}

# REMOVE TEMP MODULE LIST
If ($ModuleList) {
	Remove-Variable -Name ModuleList
}
	
# SET WINDOWS PATCHING MODULE DEFAULTS
If ((Get-Module | Select-Object -ExpandProperty Name | Out-String) -match "WindowsPatching") {
	Set-WindowsPatchingDefaults -UpdateServer "wsus01.domain.com" -UpdateServerURL "http://wsus01.domain.com" -UpdateServerPort "80" -Quiet
}
```

## Usage Summary

1. Optional: Create Host list files
2. Run Test-WSUSClient against hosts to patch
3. Fix any issues with remote hosts
4. Run Install-Patches
5. Review Results


## Disclaimer

Use at your own risk. I am not responsible for any negative impacts caused by using this module or following my instructions.

I am sharing this for educational purposes. 

I hope it helps and you enjoy my hard work. :)
