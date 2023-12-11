function Invoke-LdsGroup {
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
		$ldsParamLight = $ldsParam | ConvertTo-PSFHashtable -Exclude Partition
		$systemProperties = 'ObjectClass', 'Path', 'Name', 'GroupScope'
	}
	process {
		if (-not $TestResult) {
			$TestResult = Test-LdsGroup @ldsParam -Delete:$Delete
		}
		foreach ($testItem in $TestResult) {
			switch ($testItem.Action) {
				'Create' {
					$attributes = $testItem.Configuration | ConvertTo-PSFHashtable -Exclude $systemProperties
					$newParam = @{
						Name = $testItem.Configuration.Name
						GroupScope = $testItem.Configuration.GroupScope
						Path = ($testItem.Identity -replace '^.+?,')
					}
					if (0 -lt $attributes.Count) { $newParam.OtherAttributes = $attributes }
					if (-not $newParam.GroupScope) { $newParam.GroupScope = 'DomainLocal' }
					New-ADGroup @ldsParamLight @newParam
				}
				'Delete' {
					Remove-ADGroup @ldsParam -Identity $testItem.ADObject.ObjectGUID -Recursive -Confirm:$false
				}
				'Update' {
					$update = @{ }
					foreach ($change in $testItem.Change) {
						$update[$change.Property] = $change.New
					}
					Set-ADObject @ldsParam -Identity $testItem.ADObject.ObjectGUID -Replace $update
				}
			}
		}
	}
}