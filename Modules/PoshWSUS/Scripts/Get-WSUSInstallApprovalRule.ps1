Function Get-WSUSInstallApprovalRule {
<#  
.SYNOPSIS  
    Lists the currently configured Automatic Install Approval Rules on WSUS.
    
.DESCRIPTION
    Lists the currently configured Automatic Install Approval Rules on WSUS.
    
.NOTES  
    Name: Get-WSUSInstallApprovalRules
    Author: Boe Prox
    DateCreated: 08DEC2010 
           
.LINK  
    https://learn-powershell.net
    
.EXAMPLE 
Get-WSUSInstallApprovalRules

Description
-----------  
This command will display the configuration information for the WSUS connection to a database.       
#> 
[cmdletbinding()]  
    Param()
    Process {
        $wsus.GetInstallApprovalRules()        
    }
}