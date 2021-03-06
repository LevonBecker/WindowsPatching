function Start-WSUSCleanup {
    <#  
    .SYNOPSIS  
        Performs a cleanup on WSUS based on user inputs.
        
    .DESCRIPTION
        Performs a cleanup on WSUS based on user inputs.
        
    .PARAMETER DeclineSupersededUpdates
        Declined Superseded Updates will be removed.
        
    .PARAMETER DeclineExpiredUpdates
        Expired updates should be declined.
        
    .PARAMETER CleanupObsoleteUpdates
        Delete obsolete updates from the database.
        
    .PARAMETER CompressUpdates
        Obsolete revisions to updates should be deleted from the database.
        
    .PARAMETER CleanupObsoleteComputers
        Delete obsolete computers from the database.
        
    .PARAMETER CleanupUnneededContentFiles 
        Delete unneeded update files.   
        
    .NOTES  
        Name: Start-WSUSCleanup
        Author: Boe Prox
        DateCreated: 24SEPT2010            
    .LINK  
        https://learn-powershell.net
        
    .EXAMPLE  
    Start-WSUSCleanup -CompressUpdates -CleanupObsoleteComputers

    Description
    ----------- 
    This command will run the WSUS cleanup wizard and delete obsolete computers from the database and delete obsolete update 
    revisions from the database. 
     
    .EXAMPLE 
    Start-WSUSCleanup -CompressUpdates -CleanupObsoleteComputers -DeclineExpiredUpdates -CleanupObsoleteUpdates -CleanupUnneededContentFiles 

    Description
    ----------- 
    This command performs a full WSUS cleanup against the database.      
    #> 
    [cmdletbinding(
    	ConfirmImpact = 'low',
        SupportsShouldProcess = $True
    )]
        Param(
            [Parameter(
                Mandatory = $False,
                Position = 0)]
                [switch]$DeclineSupersededUpdates,   
            [Parameter(
                Mandatory = $False,
                Position = 1)]
                [switch]$DeclineExpiredUpdates,  
            [Parameter(
                Mandatory = $False,
                Position = 2)]
                [switch]$CleanupObsoleteUpdates,  
            [Parameter(
                Mandatory = $False,
                Position = 3)]
                [switch]$CompressUpdates,  
            [Parameter(
                Mandatory = $False,
                Position = 4)]
                [switch]$CleanupObsoleteComputers,  
            [Parameter(
                Mandatory = $False,
                Position = 5)]
                [switch]$CleanupUnneededContentFiles                                                                                                     
                ) 
    Begin {            
        #Create cleanup scope
        $cleanScope = new-object Microsoft.UpdateServices.Administration.CleanupScope
        #Create cleanup manager object
        $cleanup = $wsus.GetCleanupManager()

        #Determine what will be in the scope
        If ($PSBoundParameters['DeclineSupersededUpdates']) {
            $cleanScope.DeclineSupersededUpdates = $True
        }
        If ($PSBoundParameters['DeclineExpiredUpdates']) {
            $cleanScope.DeclineExpiredUpdates = $True
        }
        If ($PSBoundParameters['CleanupObsoleteUpdates']) {
            $cleanScope.CleanupObsoleteUpdates = $True
        }        
        If ($PSBoundParameters['CompressUpdates']) {
            $cleanScope.CompressUpdates = $True
        }
        If ($PSBoundParameters['CleanupObsoleteComputers']) {
            $cleanScope.CleanupObsoleteComputers = $True
        }
        If ($PSBoundParameters['CleanupUnneededContentFiles']) {
            $cleanScope.CleanupUnneededContentFiles = $True
        }
    }
    Process {
        Write-Host "Beginning cleanup, this may take some time..." -fore green -background black                
        If ($pscmdlet.ShouldProcess($($wsus.name))) {
            $cleanup.PerformCleanup($cleanScope)
        }     
    }                        
}