function Reset-WSUSContent {
    <#  
    .SYNOPSIS  
        Forces a synchronization of WSUS content and metadata.
    .DESCRIPTION
        Forces a synchronization of WSUS content and metadata.
    .NOTES  
        Name: Reset-WSUSContent
        Author: Boe Prox
        DateCreated: 04FEB2011 
               
    .LINK  
        https://learn-powershell.net
    .EXAMPLE
    Reset-WSUSContent

    Description
    -----------
    This command will force the synchronization of all update metadata on the WSUS server and verifies all update files on WSUS are valid.  
           
    #> 
    [cmdletbinding()]  
    Param () 
    Process {
        #Reset the WSUS content and verify files   
        $wsus.ResetAndVerifyContentState()
    }
}