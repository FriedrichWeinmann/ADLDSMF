function Invoke-LdsGroupMembership {
	<#
	.SYNOPSIS
		Applies the configuration-defined group memberships.
	
	.DESCRIPTION
		Applies the configuration-defined group memberships.
		It is generally good idea to apply groups and users first.
	
	.PARAMETER Server
		The LDS Server to target.
	
	.PARAMETER Partition
		The Partition on the LDS Server to target.
	
	.PARAMETER Credential
		Credentials to use for the operation.
	
	.PARAMETER Delete
		Undo everything defined in configuration.
		Allows rolling back after deployment.
	
	.PARAMETER TestResult
		Result objects of the associated Test-Command.
		Allows cherry-picking which change to apply.
		If not specified, it will a test and apply all test results instead.
	
	.EXAMPLE
		PS C:\> Invoke-LdsGroupMembership -Server lds1.contoso.com -Partition 'DC=fabrikam,DC=org'

		Applies the configuration-defined group memberships against 'DC=fabrikam,DC=org' on lds1.contoso.com.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Server,

		[Parameter(Mandatory = $true)]
		[string]
		$Partition,

		[PSCredential]
		$Credential,

		[switch]
		$Delete,

		[Parameter(ValueFromPipeline = $true)]
		$TestResult
	)
	
	begin {
		Update-LdsConfiguration -LdsServer $Server -LdsPartition $Partition
		$ldsParam = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Partition, Credential
	}
	process {
		if (-not $TestResult) {
			$TestResult = Test-LdsGroupMembership @ldsParam -Delete:$Delete
		}
		foreach ($testItem in $TestResult) {
			switch ($testItem.Action) {
				'Update' {
					foreach ($change in $testItem.Change) {
						switch ($change.Action) {
							'Add' { Add-ADGroupMember @ldsParam -Identity $testItem.ADObject -Members $change.DN }
							'Remove' { Remove-ADGroupMember @ldsParam -Identity $testItem.ADObject -Members $change.DN }
						}
					}
				}
			}
		}
	}
}
