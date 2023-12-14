function Test-LdsConfiguration {
	<#
	.SYNOPSIS
		Test all configured settings against the target LDS instance.
	
	.DESCRIPTION
		Test all configured settings against the target LDS instance.
	
	.PARAMETER Server
		The LDS Server to target.
	
	.PARAMETER Partition
		The Partition on the LDS Server to target.
	
	.PARAMETER Credential
		Credentials to use for the operation.
	
	.PARAMETER Options
		Which part of the configuration to test for.
		Defaults to all of them ('User', 'Group', 'OrganizationalUnit', 'GroupMembership', 'AccessRule', 'SchemaAttribute')

	.PARAMETER Delete
		Undo everything defined in configuration.
		Allows rolling back after deployment.
	
	.EXAMPLE
		PS C:\> Test-LdsConfiguration -Server lds1.contoso.com -Partition 'DC=Fabrikam,DC=org'

		Test all configured settings against the 'DC=Fabrikam,DC=org' LDS instance on server lds1.contoso.com.
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

		[ValidateSet('User', 'Group', 'OrganizationalUnit', 'GroupMembership', 'AccessRule', 'SchemaAttribute')]
		[string[]]
		$Options = @('User', 'Group', 'OrganizationalUnit', 'GroupMembership', 'AccessRule', 'SchemaAttribute'),

		[switch]
		$Delete
	)
	
	begin {
		$ldsParam = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Partition, Credential, Delete
	}
	process {
		if ($Options -contains 'SchemaAttribute' -and -not $Delete) {
			Test-LdsSchemaAttribute @ldsParam
		}
		if ($Options -contains 'OrganizationalUnit') {
			Test-LdsOrganizationalUnit @ldsParam
		}
		if ($Options -contains 'Group') {
			Test-LdsGroup @ldsParam
		}
		if ($Options -contains 'User') {
			Test-LdsUser @ldsParam
		}
		if ($Options -contains 'GroupMembership') {
			Test-LdsGroupMembership @ldsParam
		}
		if ($Options -contains 'AccessRule') {
			Test-LdsAccessRule @ldsParam
		}
	}
}