function Invoke-LdsGroupMembership {
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
			$TestResult = Test-LdsGroupMembership @ldsParam
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
