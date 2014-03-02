function New-WSUSGroup {
    <#  
    .SYNOPSIS  
        Creates a new WSUS Target group.
        
    .DESCRIPTION
        Creates a new WSUS Target group.
        
    .PARAMETER Name
        Name of group being created.
        
    .PARAMETER ParentGroup
        Parent group to add child group to.
    
    .PARAMETER PassThru
               
    .NOTES  
        Name: New-WSUSGroup
        Author: Boe Prox
        DateCreated: 24SEPT2010 
               
    .LINK  
        https://learn-powershell.net
        
    .EXAMPLE 
    New-WSUSGroup -name "TestGroup"

    Description
    -----------  
    This command will create a new Target group called 'TestGroup'   
        
    .EXAMPLE 
    Get-WSUSGroup -Name 'Domain Servers' | New-WSUSGroup -name "TestGroup"

    Description
    -----------  
    This command will create a new Target group called 'TestGroup' under the parent group 'Domain Servers'    
    #> 
    [cmdletbinding(
    	DefaultParameterSetName = 'group',
    	ConfirmImpact = 'low',
        SupportsShouldProcess = $True
    )]
    Param(
        [Parameter(
            Mandatory = $True,
            Position = 0,
            ParameterSetName = '',
            ValueFromPipeline = $True)]
            [string]$Name,
        [Parameter(
            Mandatory = $False,
            Position = 1,
            ParameterSetName = 'parentgroup',
            ValueFromPipeline = $True)]
            [Microsoft.UpdateServices.Internal.BaseApi.ComputerTargetGroup]$ParentGroup,
        [Parameter(
            Mandatory = $False,
            Position = 2)]
            [switch]$PassThru                                                            
    ) 
    Process {
        Try {
            #Determine action based on Parameter Set Name
            Switch ($pscmdlet.ParameterSetName) {            
                "group" {
                    Write-Verbose "Creating computer group"        
                    If ($pscmdlet.ShouldProcess($Name)) {
                        #Create the computer target group
                        $Group = $wsus.CreateComputerTargetGroup($Name)
                    }
                }                
                "parentgroup" {                    
                    Write-Verbose "Creating computer group"                
                    If ($pscmdlet.ShouldProcess($Name)) {
                        #Create the computer target group
                        $Group = $wsus.CreateComputerTargetGroup($Name,$parentgroup)
                    }            
                }                
            }
        } Catch {
            Write-Warning ("{0}" -f $_.Exception.Message)
        }
    }                
    End {
        If ($PSBoundParameters['PassThru']) {
            Write-Output $Group
        }
    }
} 