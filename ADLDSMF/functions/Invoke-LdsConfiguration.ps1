function Invoke-LdsConfiguration {
	<#
	.SYNOPSIS
		Applies all currently configured settings to the target AD LDS server.
	
	.DESCRIPTION
		Applies all currently configured settings to the target AD LDS server.
		Use Import-LdsConfiguration first to load one or more configuration sets.
	
	.PARAMETER Server
		The LDS Server to target.
	
	.PARAMETER Partition
		The Partition on the LDS Server to target.
	
	.PARAMETER Credential
		Credentials to use for the operation.
	
	.PARAMETER Options
		Which part of the configuration to deploy.
		Defaults to all of them ('User', 'Group', 'OrganizationalUnit', 'GroupMembership', 'AccessRule', 'SchemaAttribute')

	.PARAMETER Delete
		Undo everything defined in configuration.
		Allows rolling back after deployment.
		
	.EXAMPLE
		PS C:\> Invoke-LdsConfiguration -Server lds1.contoso.com -Partition 'DC=fabrikam,DC=org'
		
		Applies all currently configured settings to the target AD LDS server.
		
	.EXAMPLE
		PS C:\> Invoke-LdsConfiguration -Server lds1.contoso.com -Partition 'DC=fabrikam,DC=org' -Options User, Group, OrganizationalUnit
		
		Applies all currently configured users, groups and OUs to the target AD LDS server.
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
		$ldsParam = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Partition, Credential
	}
	process {
		if ($Options -contains 'SchemaAttribute') {
			Invoke-LdsSchemaAttribute @ldsParam
		}
		if ($Options -contains 'OrganizationalUnit') {
			Invoke-LdsOrganizationalUnit @ldsParam -Delete:$Delete
		}
		if ($Options -contains 'Group') {
			Invoke-LdsGroup @ldsParam -Delete:$Delete
		}
		if ($Options -contains 'User') {
			Invoke-LdsUser @ldsParam -Delete:$Delete
		}
		if ($Options -contains 'GroupMembership') {
			Invoke-LdsGroupMembership @ldsParam -Delete:$Delete
		}
		if ($Options -contains 'AccessRule') {
			Invoke-LdsAccessRule @ldsParam -Delete:$Delete
		}
	}
}