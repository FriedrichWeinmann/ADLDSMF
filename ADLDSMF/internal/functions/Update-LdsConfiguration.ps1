function Update-LdsConfiguration {
	<#
	.SYNOPSIS
		Updates the reference to the currently "connected to" LDS instance.
	
	.DESCRIPTION
		Updates the reference to the currently "connected to" LDS instance.
		This is used by Get-LdsDomain, which is injected into the ADSec module to avoid issues with domain resolution.
	
	.PARAMETER LdsServer
		The server hosting the LDS instance.
	
	.PARAMETER LdsPartition
		The partition of the LDS instance.
	
	.EXAMPLE
		PS C:\> Update-LdsConfiguration -LdsServer lds1.contoso.com -LdsPartition 'DC=Fabrikam,DC=org'
		
		Registers lds1.contoso.com as the current server and 'DC=Fabrikam,DC=org' as the current partition.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$LdsServer,

		[Parameter(Mandatory = $true)]
		[string]
		$LdsPartition
	)

	$script:_ldsServer = $LdsServer
	$script:_ldsPartition = $LdsPartition
}