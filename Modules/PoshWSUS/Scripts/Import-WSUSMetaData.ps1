function Import-WSUSMetaData {
    <#  
    .SYNOPSIS  
        Imports WSUS metadata from a previous export onto a different WSUS server
        
    .DESCRIPTION
        Imports WSUS metadata from a previous export onto a different WSUS server
        
    .PARAMETER FileName
        Name of the metadata file to import
    
    .PARAMETER LogName
        Name of the logfile that is generated during import
        
    .NOTES  
        Name: Import-WSUSMetaData
        Author: Boe Prox
        DateCreated: 15NOV2011
               
    .LINK  
        https://learn-powershell.net
        
    .EXAMPLE  
    Import-WSUSMetaData -FileName "WSUSMetadata.cab" -LogName "C:\temp\wsusimport.log"

    Description
    -----------      
    Imports the wsus metadata from the specified file.
           
    #> 
    [cmdletbinding(
    	ConfirmImpact = 'low',
        SupportsShouldProcess = $True        
    )]
        Param(
            [Parameter(Mandatory=$True,Position = 0,ValueFromPipeline = $True)]
            [string]$FileName,  
            [Parameter(Mandatory=$True,Position = 1,ValueFromPipeline = $True)]
            [string]$LogName                                                            
        )
    Process {
        If ($pscmdlet.ShouldProcess($FileName,"Import MetaData")) {
            Try {
                Write-Host ("Importing WSUS Metadata from {0}`nThis may take a while." -f $FileName) -Fore Green -Background Black
                $Wsus.ExportUpdates($FileName,$LogName)
            } Catch {
                Write-Warning ("Unable to import metadata!`n{0}" -f $_.Exception.Message)
            }
        }
    } 
}