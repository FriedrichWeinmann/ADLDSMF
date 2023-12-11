function Invoke-LdsAccessRule {
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
			$TestResult = Test-LdsAccessRule @ldsParam -Partition $Partition
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