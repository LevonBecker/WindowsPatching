#requires –version 2.0

Function Get-PendingPatches {
	Param (
	[parameter(Position=0,Mandatory=$true)][string]$ComputerName
#	[parameter(Mandatory=$false)][string]$SubScripts = ($Global:WindowsPatchingDefaults.SubScripts)
	)
	# CLEAR VARIBLES
	[boolean]$Success= $false
	[string]$Notes = $null
	[datetime]$SubStartTime = Get-Date
	
	$UpdateSession = $null
	$UpdateSearcher = $null
	$SearchResult = $null
	$Update = $null
	[int]$PatchCount = 0
	$Report = @()
	
	# . "$SubScripts\Func_Get-Runtime_1.0.3.ps1"
	
	# REMOVE EXISTING OUTPUT PSOBJECT	
	If ($Global:GetPendingPatches) {
		Remove-Variable GetPendingPatches -Scope "Global"
	}
	
    Write-Verbose "ComputerName: $($ComputerName)" 
	$Script:ErrorActionPreference = 'Stop'
    Try { 
    #Create Session COM object 
        Write-Verbose "Creating COM object for WSUS Session" 
        $UpdateSession =  [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session",$ComputerName))
		[Boolean]$CreateObjSuccess = $true
		[string]$COMError = "N/A"
        } 
    Catch { 
#        Write-Warning "$($Error[0])" 
        [string]$Notes += 'ERROR: COM Object Creation Failed - '
		[string]$COMError = "$($Error[0])"
		[Boolean]$CreateObjSuccess = $false
        } 
	$Script:ErrorActionPreference = 'Continue'
	
	If ($CreateObjSuccess -eq $true) {
        #Configure Session COM Object 
        Write-Verbose "Creating COM object for WSUS update Search" 
        $UpdateSearcher = $UpdateSession.CreateUpdateSearcher() 

        #Configure Searcher object to look for Updates awaiting installation 
        Write-Verbose "Searching for WSUS updates on ComputerName" 
        $SearchResult = $UpdateSearcher.Search("IsInstalled=0")     
         
        #Verify if Updates need installed 
        Write-Verbose "Verifing that updates are available to install" 
        If ($SearchResult.Updates.Count -gt 0) { 
            #Updates are waiting to be installed 
            Write-Verbose "Found $($SearchResult.Updates.Count) update\s!" 
            #Cache the count to make the For loop run faster 
            [int]$PatchCount = $SearchResult.Updates.Count 
             
            #Begin iterating through Updates available for installation 
            Write-Verbose "Iterating through List of updates" 
            For ($i=0; $i -lt $PatchCount; $i++) {
                #Create object holding update 
                $Update = $SearchResult.Updates.Item($i) 
                 
                #Verify that update has been downloaded 
                Write-Verbose "Checking to see that update has been downloaded" 
                If ($Update.IsDownLoaded -eq "True") {  
                    Write-Verbose "Auditing updates"
                    $temp = "" | Select ComputerName, Title, KB,IsDownloaded 
                    $temp.ComputerName = $ComputerName 
                    $temp.Title = ($Update.Title -split('\('))[0] 
                    $temp.KB = (($Update.title -split('\('))[1] -split('\)'))[0] 
                    $temp.IsDownloaded = "True" 
                    $Report += $temp
					[Boolean]$Success = $true
                    } 
                Else { 
                    Write-Verbose "Update has not been downloaded yet."
                    $temp = "" | Select ComputerName, Title, KB,IsDownloaded 
                    $temp.ComputerName = $ComputerName 
                    $temp.Title = ($Update.Title -split('\('))[0] 
                    $temp.KB = (($Update.title -split('\('))[1] -split('\)'))[0] 
                    $temp.IsDownloaded = "False" 
                    $Report += $temp
					[Boolean]$Success = $true
                    } 
                } # For Loop
            } # If Pending Updates Found
        Else { 
            #Nothing to install at this time 
            Write-Verbose "No updates to install." 
             
            #Create Temp collection for report 
            $temp = "" | Select ComputerName, Title, KB,IsDownloaded 
            $temp.ComputerName = $ComputerName 
            $temp.Title = "N/A" 
            $temp.KB = "N/A" 
            $temp.IsDownloaded = "N/A" 
            $Report += $temp
			[string]$Notes += 'No Updates to Install - '
			[Boolean]$Success = $true
        }
	}
    Else { 
        #Failed
#        Write-Warning "Create COM Object Failure" 
         
        #Create Temp collection for report 
        $temp = "" | Select ComputerName, Title, KB,IsDownloaded 
        $temp.ComputerName = $ComputerName 
        $temp.Title = "N/A" 
        $temp.KB = "N/A" 
        $temp.IsDownloaded = "N/A" 
        $Report += $temp             
        } 

    Get-Runtime -StartTime $SubStartTime

	# Create Results Custom PS Object
	$Global:GetPendingPatches = New-Object -TypeName PSObject -Property @{
		ComputerName = $ComputerName
		Success = $Success
		Notes = $Notes 
		Starttime = $SubStartTime
		Endtime = $Global:GetRuntime.Endtime
		Runtime = $Global:GetRuntime.Runtime
		Report = $Report
		PatchCount = $PatchCount
		Error = $COMError
	}
} # Function

#region Notes

<# Description
	Get a list of Windows Patches on remote computer pending install.
#>

<# Author
	Levon Becker
	PowerShell.Guru@BonusBits.com
	http://wiki.bonusbits.com
#>

<# Dependents
	Get-PendingUpdates
#>

<# Dependencies
	Func_Get-Runtime
#>

<# To Do List
	
#>

<# Change Log
	1.0.0 - 05/14/2012
		Created
#>

<# Sources
	http://gallery.technet.microsoft.com/scriptcenter/0dbfc125-b855-4058-87ec-930268f03285
#>

#endregion Notes
