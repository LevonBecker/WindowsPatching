function Get-WSUSStatus {
    <#  
    .SYNOPSIS  
        Retrieves a list of all updates and their statuses along with computer statuses.
    .DESCRIPTION
        Retrieves a list of all updates and their statuses along with computer statuses.   
    .NOTES  
        Name: Get-WSUSStatus
        Author: Boe Prox
        DateCreated: 24SEPT2010 
               
    .LINK  
        https://learn-powershell.net
    .EXAMPLE 
    Get-WSUSStatus 

    Description
    -----------
    This command will display the status of the WSUS server along with update statuses.
           
    #> 
    [cmdletbinding()]  
    Param () 
    Process {
        $wsus.getstatus()      
    }
} 