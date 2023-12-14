function Invoke-LdsOrganizationalUnit {
	<#
	.SYNOPSIS
		Creates the desired organizational units.
	
	.DESCRIPTION
		Creates the desired organizational units.
	
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
		PS C:\> Invoke-LdsOrganizationalUnit -Server lds1.contoso.com -Partition 'DC=fabrikam,DC=org'
		
		Creates the desired organizational units in 'DC=fabrikam,DC=org' on lds1.contoso.com
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
		$ldsParamLight = $ldsParam | ConvertTo-PSFHashtable -Exclude Partition
		$systemProperties = 'ObjectClass', 'Path', 'Name'
		$filter = {
			# Delete actions should go from innermost to top-level
			# Create actions should go from top-level to most nested
			if ($_.Action -eq 'Delete') { $_.Identity.Length * -1 }
			else { $_.Identity.Length }
		}
	}
	process {
		if (-not $TestResult) {
			$TestResult = Test-LdsOrganizationalUnit @ldsParam -Delete:$Delete
		}
		foreach ($testItem in $TestResult | Sort-Object Action, $filter) {
			switch ($testItem.Action) {
				'Create' {
					$attributes = $testItem.Configuration | ConvertTo-PSFHashtable -Exclude $systemProperties
					$newParam = @{
						Name = $testItem.Configuration.Name
						Path = ($testItem.Identity -replace '^.+?,')
					}
					if (0 -lt $attributes.Count) { $newParam.OtherAttributes = $attributes }
					New-ADOrganizationalUnit @ldsParamLight @newParam
				}
				'Delete' {
					Unprotect-OrganizationalUnit @ldsParam -Identity $testItem.ADObject.ObjectGUID
					Remove-ADOrganizationalUnit @ldsParam -Identity $testItem.ADObject.ObjectGUID -Recursive -Confirm:$false
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