function Invoke-LdsUser {
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
		$systemProperties = 'ObjectClass', 'Path', 'Name', 'Enabled'
	}
	process {
		if (-not $TestResult) {
			$TestResult = Test-LdsUser @ldsParam -Delete:$Delete
		}
		foreach ($testItem in $TestResult) {
			switch ($testItem.Action) {
				'Create' {
					$attributes = $testItem.Configuration | ConvertTo-PSFHashtable -Exclude $systemProperties
					$newParam = @{
						Name = $testItem.Configuration.Name
						Path = ($testItem.Identity -replace '^.+?,')
						OtherAttributes = $attributes
					}
					if ($testItem.Configuration.Enabled) {
						$newParam += @{
							Enabled = $true
							AccountPassword = New-Password -AsSecureString
						}
					}
					if (0 -eq $newParam.OtherAttributes.Count) { $newParam.Remove('OtherAttributes') }
					New-ADUser @ldsParamLight @newParam
				}
				'Delete' {
					Remove-ADUser @ldsParam -Identity $testItem.ADObject.ObjectGUID -Recursive -Confirm:$false
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