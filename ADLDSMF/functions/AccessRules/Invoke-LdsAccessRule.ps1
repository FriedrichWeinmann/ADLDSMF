function Invoke-LdsAccessRule {
	<#
	.SYNOPSIS
		Applies all the configured access rules.
	
	.DESCRIPTION
		Applies all the configured access rules.
	
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
		PS C:\> Invoke-LdsAccessRule -Server lds1.contoso.com -Partition 'DC=fabrikam,DC=org'

		Apply all configured access rules to the 'DC=fabrikam,DC=org' partition on lds1.contoso.com
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
		Update-ADSec
		Update-LdsConfiguration -LdsServer $Server -LdsPartition $Partition
		$ldsParam = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
	}
	process {
		if (-not $TestResult) {
			$TestResult = Test-LdsAccessRule @ldsParam -Partition $Partition -Delete:$Delete
		}
		foreach ($testItem in $TestResult | Sort-Object Action -Descending) {
			switch ($testItem.Action) {
				'Add' {
					$acl = Get-AdsAcl @ldsParam -Path $testItem.Identity
					$acl.AddAccessRule($testItem.Change.Rule)
					$acl | Set-AdsAcl @ldsParam -Path $testItem.Identity
				}
				'Remove' {
					$acl = Get-AdsAcl @ldsParam -Path $testItem.Identity
					$null = $acl.RemoveAccessRule($testItem.Change.Rule)
					$acl | Set-AdsAcl @ldsParam -Path $testItem.Identity
				}
			}
		}
	}
}