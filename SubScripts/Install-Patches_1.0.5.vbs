'VERSION: 	1.0.3
'TITLE:		Search, Download and Install Windows Patches with Windows Update Agent (WUA)	
'PURPOSE:	Search, Download and Install Windows Patches on the localhost.
'			Patches are pulled from the WSUS server that the localhost is configured for.
'AUTHOR:	Levon Becker
'NOTES:		Must have Windows Update Agent installed. This replaces VBScript for Update.vbs that eliminate.
'SOURCES:	http://msdn.microsoft.com/en-us/library/windows/desktop/aa387102%28v=vs.85%29.aspx
'
'CHANGELOG:	
'1.0.0 - 10/13/2011
'	Created
'1.0.1 - 10/14/2011
'	Troubleshooting why log file is not getting created on Win2K
'1.0.2 - 05/03/2012
'	Changed Path from C:\Windows-Patching to C:\WindowsPatching
'1.0.3 - 05/15/2012
'   Changed Log name to _InstallPatches_Temp.log
'   Rename Script to Install-Patches_1.0.3.vbs
'1.0.4 - 05/03/2012
'	Changed Path from C:\WindowsPatching to C:\WindowsScriptsTemp
'1.0.5 - 11/27/2012
'	Changed Path from C:\WindowsScriptsTemp to C:\WindowsScriptTemp


ON ERROR RESUME NEXT
CONST ForAppending = 8
CONST ForWriting = 2
CONST ForReading = 1

strlocalhost = "."
Set oShell = CreateObject("WScript.Shell") 

' Create WUA Session Com Object
Set updateSession = CreateObject("Microsoft.Update.Session")
Set updateSearcher = updateSession.CreateupdateSearcher()

' Get Hostname with WMI object
Set objWMI = GetObject("winmgmts:\\" & strlocalhost & "\root\CIMV2")
Set colitems = objWMI.ExecQuery("SELECT Name FROM Win32_ComputerSystem")
	For Each objcol in colitems
		'WScript.Echo "Name: " & objcol.Name
		strcomputer = objcol.Name
	Next

' Create Last Patch Text File Locally with Hostname included in the filename and inserted in the log
Set ofso = createobject("scripting.filesystemobject")
Set objtextfile = ofso.createtextfile("C:\WindowsScriptTemp\" & strcomputer & "_InstallPatches_Temp.log", True)
objtextfile.writeline strcomputer

WScript.Echo "Searching for updates..." & vbCRLF

Set searchResult = updateSearcher.Search("IsInstalled=0 and Type='Software'")

WScript.Echo "List of applicable items on the machine:"

' If No Updates Needed: write to log and exit
If searchResult.Updates.Count = 0 Then
	WScript.Echo "There are no applicable updates."
	objtextfile.writeline "No updates to install."
	WScript.Quit
End If

For I = 0 To searchResult.Updates.Count-1
    Set update = searchResult.Updates.Item(I)
    WScript.Echo I + 1 & "> " & update.Title
Next

' Create Collection of updates to Download
WScript.Echo vbCRLF & "Creating collection of updates to download:"

' Create WUA Update Collection Object for Downloading
Set updatesToDownload = CreateObject("Microsoft.Update.UpdateColl")

' Load of Needed Updates into Collection Object to Download
For I = 0 to searchResult.Updates.Count-1
    Set update = searchResult.Updates.Item(I)
    WScript.Echo I + 1 & "> adding: " & update.Title 
    updatesToDownload.Add(update)
Next

' Start Updates Download
WScript.Echo vbCRLF & "Downloading updates..."

Set downloader = updateSession.CreateUpdateDownloader() 
downloader.Updates = updatesToDownload
downloader.Download()

' List Downloaded Updates
WScript.Echo  vbCRLF & "List of downloaded updates:"

For I = 0 To searchResult.Updates.Count-1
    Set update = searchResult.Updates.Item(I)
    If update.IsDownloaded Then
       WScript.Echo I + 1 & "> " & update.Title 
    End If
Next

' Create WUA Update Collection Com Object for Installing that are downloaded
Set updatesToInstall = CreateObject("Microsoft.Update.UpdateColl")

WScript.Echo  vbCRLF & "Creating collection of downloaded updates to install:" 

For I = 0 To searchResult.Updates.Count-1
    set update = searchResult.Updates.Item(I)
    If update.IsDownloaded = true Then
       WScript.Echo I + 1 & "> adding:  " & update.Title 
       updatesToInstall.Add(update)	
    End If
Next

' Clear Errors before installation attempt
err.clear

' Install Updates in Collection Install Object
WScript.Echo "Installing updates..."
objtextfile.writeline vbcrlf & vbcrlf & "Installing updates..." & vbcrlf

Set installer = updateSession.CreateUpdateInstaller()
installer.Updates = updatesToInstall
Set installationResult = installer.Install()

' Error Handling
If err.number <> 0 Then
	' Output any errors to the log file
	WScript.Echo "Error Occurred installing " & update.Title
	WScript.Echo "Error: " & err.number
	WScript.Echo "Descr: " & err.description
	objtextfile.writeline "Error Occurred installing " & update.Title
	objtextfile.writeline "Error: " & err.number
	objtextfile.writeline "Descr: " & err.description
	objtextfile.writeline vbcrlf
Else	
	' Output results of install
	WScript.Echo "Installation Result: " & installationResult.ResultCode 
	WScript.Echo "Reboot Required: " & installationResult.RebootRequired & vbCRLF 
	WScript.Echo "Listing of updates installed " & "and individual installation results:" 
	objtextfile.writeline "Installation Result: " & installationResult.ResultCode 
	objtextfile.writeline "Reboot Required: " & installationResult.RebootRequired & vbCRLF 
	objtextfile.writeline "Listing of updates installed " & "and individual installation results:" 

	' Output Title and Result for each Update Install attempt to the console and log file
	For I = 0 to updatesToInstall.Count - 1
		WScript.Echo I + 1 & "> " & _
		updatesToInstall.Item(i).Title & ": " & installationResult.GetUpdateResult(i).ResultCode 
		objtextfile.writeline I + 1 & "> " & updatesToInstall.Item(i).Title & ": " & installationResult.GetUpdateResult(i).ResultCode		
	Next
End If

Wscript.Quit
REM End If