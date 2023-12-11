function Update-LdsConfiguration {
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