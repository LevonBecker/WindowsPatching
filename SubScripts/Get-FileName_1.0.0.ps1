#requires –version 2.0

Function Get-FileName {

#region Help

<#
.SYNOPSIS
	Produces a Dialog box to select a file from the file system.
.DESCRIPTION
	A poppup dialog box that allows you to pick a file from the local system. This can be good for selecting a file as input.
.NOTES
	AUTHOR:  Levon Becker
	STATE:	 Alpha
.EXAMPLE
	Get-FileName "C:\InputLists"
.EXAMPLE
	Get-FileName -InitialDirectory "C:\ScriptLogs\WindowsPatching\InputLists" -Filter "txt files (.txt)|*.txt"
.PARAMETER InitialDirectory
	Folder to initially open.
.PARAMETER Filter
	This parameter sets the file type to look for.
.PARAMETER PubPSScripts
	Public PowerShell Sub Scripts Path.
.LINK
	http://wiki.bonusbits.com:PSScript:Get-FileName
#>

#endregion Help
	[CmdletBinding()]
	Param (
		[parameter(Position=0,Mandatory=$false)][string]$InitialDirectory = "C:\",
		[parameter(Position=1,Mandatory=$false)][string]$Filter = "All files (*.*)| *.*"
	)
	# CLEAR VARIBLES
	[boolean]$Success= $false
	[string]$Notes = ''
	
	# REMOVE EXISTING OUTPUT PSOBJECT	
	If ($global:GetFileName) {
		Remove-Variable GetFileName -Scope "Global"
	}
	
	#region Tasks
		
		Do {
			[void][System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")
			$OpenFileDialog = $null
			$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
			$OpenFileDialog.InitialDirectory = $InitialDirectory
			$OpenFileDialog.Filter = $Filter
			$OpenFileDialog.ShowHelp = $true
			$OpenFileDialog.ShowDialog() | Out-Null
			$FullName = $OpenFileDialog.Filename
			$FileName = $OpenFileDialog.SafeFileName
		}
		Until ($FileName)
		
#		If($OpenFileDialog.ShowDialog() -eq "OK") {
#			$OpenFileDialog.FileName
#		}
	
	#endregion Tasks
	
	# Create Results Custom PS Object
	$global:GetFileName = New-Object -TypeName PSObject -Property @{
		InitialDirectory = $InitialDirectory
		Success = $Success
		Notes = $Notes
		Filter = $Filter
		FileName = $FileName
		FullName = $FullName
	}
}

#region Notes

<# Description
	Function to create a pop up windows to browse the filesystem for a file. 
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Get-PendingUpdates
	Install-Patches
	Test-WSUSClient
#>

<# Dependencies
#>

<# To Do List
	
#>

<# Change Log
1.0.0 - 04/30/2012
	Created
#>

#endregion Notes
