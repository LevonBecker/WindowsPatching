<#
To Do:
    1. New-WSUSLocalPackage
    2. Get-WSUSLocalPackage
    3. Get-WSUSUpdateApproval
    4. Set-WSUSConfiguration
    5. New-WSUSClient
#>

#Validate user is an Administrator
Write-Verbose "Checking Administrator credentials"
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You are not running this as an Administrator!`nPlease re-run module with an Administrator Account."
    Break
}

#Load Functions
$ScriptPath = Split-Path $MyInvocation.MyCommand.Path
Try {
    Get-ChildItem "$ScriptPath\Scripts" | Select -Expand FullName | ForEach {
        $Function = Split-Path $_ -Leaf
        . $_
    }
} Catch {
    Write-Warning ("{0}: {1}" -f $Function,$_.Exception.Message)
    Continue
}   

#Write-Host "`n"
#Write-Host "`t`tPoshWSUS 2.0.3"
#Write-Host "`n"
#Write-Host -nonewline "Make initial connection to WSUS Server:`t"
#Write-Host -fore Yellow "Connect-WSUSServer"
#Write-Host -nonewline "Disconnect from WSUS Server:`t`t"
#Write-Host -fore Yellow "Disconnect-WSUSServer"
#Write-Host -nonewline "List all available commands:`t`t"
#Write-Host -fore Yellow "Get-WSUSCommand"
#Write-Host "`n"