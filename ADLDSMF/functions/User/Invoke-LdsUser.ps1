﻿function Invoke-LdsUser {
	<#
	.SYNOPSIS
		Creates the intended user objects.
	
	.DESCRIPTION
		Creates the intended user objects.
	
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
		PS C:\> Invoke-LdsUser -Server lds1.contoso.com -Partition 'DC=fabrikam,DC=org'

		Creates the intended user objects for 'DC=fabrikam,DC=org' on lds1.contoso.com.
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