#requires –version 2.0

Function Get-FileEncoding {
    [CmdletBinding()] 
	Param (
    	[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)] [string]$FilePath
    )

	#region Variables
	
		[boolean]$Success = $false
		[datetime]$SubStartTime = Get-Date
		
		# REMOVE EXISTING OUTPUT PSOBJECT	
		If ($Global:GetFileEncoding) {
			Remove-Variable GetFileEncoding -Scope "Global"
		}
	
	#endregion Variables

	#region Tasks
    
		Try {
			[byte[]]$Byte = Get-Content -Encoding byte -ReadCount 4 -TotalCount 4 -Path $FilePath -ErrorAction Stop
			[Boolean]$Success = $true
		}
		Catch {
			[Boolean]$Success = $false
			[string]$Errors = "Failed to Get-Content on $Path"
		}

	    If (($Byte[0] -eq 0xef) -and ($Byte[1] -eq 0xbb) -and ($Byte[2] -eq 0xbf)) {
			[string]$Encoding = 'UTF8'
		}
		ElseIf (($Byte[0] -eq 0xfe) -and ($Byte[1] -eq 0xff)) {
			[string]$Encoding = 'BigEndianUnicode'
		}
	    ElseIf (($Byte[0] -eq 0xff) -and ($Byte[1] -eq 0xfe)) {
	    	[string]$Encoding = 'Unicode'
		}
	    ElseIf (($Byte[0] -eq 0) -and ($Byte[1] -eq 0) -and ($Byte[2] -eq 0xfe) -and ($Byte[3] -eq 0xff)) {
	    	[string]$Encoding = 'UTF32'
		}
	    ElseIf (($Byte[0] -eq 0x2b) -and ($Byte[1] -eq 0x2f) -and ($Byte[2] -eq 0x76)) {
	    	[string]$Encoding = 'UTF7'
		}
	    Else {
	    	[string]$Encoding = 'ASCII'
		}
	
	#endregion Tasks
	
	#region Results
	
		If (!$Errors) {
			[string]$Errors = 'None'
		}
	
		Get-Runtime -StartTime $SubStartTime
	
		# Create Results Custom PS Object
		$Global:GetFileEncoding = New-Object -TypeName PSObject -Property @{
			Success = $Success
			Errors = $Errors
			Starttime = $SubStartTime
			Endtime = $global:GetRuntime.Endtime
			Runtime = $global:GetRuntime.Runtime
			FilePath = $FilePath
			Encoding = $Encoding
		}
	
	#endregion Results
}