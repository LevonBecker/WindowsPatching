function Get-WSUSCurrentUserRole {
    <#  
    .SYNOPSIS  
        Returns the current role of the user.
    .DESCRIPTION
        Returns the current role of the user.
    .NOTES  
        Name: Get-WSUSCurrentUserRole
        Author: Boe Prox
        DateCreated: 04FEB2011 
               
    .LINK  
        https://learn-powershell.net
    .EXAMPLE
    Get-WSUSCurrentUserRole

    Description
    -----------
    This command will return the current role on the WSUS server.
           
    #> 
    [cmdletbinding()]  
    Param () 
    Process {
        #Return the current user role   
        $wsus.GetCurrentUserRole()
    }
}