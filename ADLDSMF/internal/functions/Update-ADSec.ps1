function Update-ADSec {
	<#
	.SYNOPSIS
		Injects Get-LdsDomain into the ADSec module to overwrite its use of Get-ADDomain.
	
	.DESCRIPTION
		Injects Get-LdsDomain into the ADSec module to overwrite its use of Get-ADDomain.
		This enables us to override the AD domain connection verification performed by the module.
	
	.EXAMPLE
		PS C:\> Update-ADSec
		
		Injects Get-LdsDomain into the ADSec module to overwrite its use of Get-ADDomain.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param ()

	& (Get-Module ADSec) {
		Set-Alias -Name Get-ADDomain -Value Get-LdsDomain -Scope Script
	}
}