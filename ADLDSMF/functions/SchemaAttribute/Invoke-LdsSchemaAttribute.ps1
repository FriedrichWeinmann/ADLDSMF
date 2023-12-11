function Invoke-LdsSchemaAttribute {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Server,

		[Parameter(Mandatory = $true)]
		[string]
		$Partition,

		[PSCredential]
		$Credential,

		[Parameter(ValueFromPipeline = $true)]
		$TestResult
	)

	begin {
		Update-LdsConfiguration -LdsServer $Server -LdsPartition $Partition
		$ldsParam = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Partition, Credential
		$ldsParamLight = $ldsParam | ConvertTo-PSFHashtable -Exclude Partition
		$systemProperties = 'ObjectClass', 'AttributeID', 'IsDeleted', 'Optional', 'MayContain'

		$rootDSE = Get-ADRootDSE @ldsParamLight
	}
	process {
		if (-not $TestResult) {
			$TestResult = Test-LdsSchemaAttribute @ldsParam
		}
		$testResultsSorted = $TestResult | Sort-Object {
			switch ($_.Action) {
				Create { 1 }
				Delete { 2 }
				Update { 3 }
				Add { 4 }
				Remove { 5 }
				Default { 6 }
			}
		}

		foreach ($testItem in $testResultsSorted) {
			switch ($testItem.Action) {
				'Create' {
					$attributes = $testItem.Configuration | ConvertTo-PSFHashtable -Exclude $systemProperties
					$attributes.AttributeID = $testItem.Configuration.AttributeID
					$name = $testItem.Configuration.Name
					if (-not $name) { $name = $testItem.Configuration.AdminDisplayName }
					New-ADObject @ldsParamLight -Type attributeSchema -Name $name -Path $rootDSE.schemaNamingContext -OtherAttributes $attributes
				}
				'Delete' {
					$testItem.ADObject | Set-ADObject @ldsParamLight -Replace @{ IsDeleted = $true }
				}
				'Update' {
					$replacements = @{ }
					foreach ($change in $testItem.Change) {
						$replacements[$change.Property] = $change.New
					}
					$testItem.ADObject | Set-ADObject @ldsParamLight -Replace $replacements
				}
				'Add' {
					$testItem.Change.Data | Set-ADObject @ldsParamLight -Add @{
						mayContain = $testItem.ADObject.lDAPDisplayName
					}
				}
				'Remove' {
					$testItem.Change.Data | Set-ADObject @ldsParamLight -Remove @{
						mayContain = $testItem.Identity
					}
				}
				'Rename' {
					$testItem.ADObject | Rename-ADObject @ldsParamLight -NewName @($testItem.Change.New)[0]
				}
			}
		}
	}
}