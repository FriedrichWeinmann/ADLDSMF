function Test-LdsConfiguration {
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
			Test-LdsSchemaAttribute @ldsParam
		}
		if ($Options -contains 'OrganizationalUnit') {
			Test-LdsOrganizationalUnit @ldsParam -Delete:$Delete
		}
		if ($Options -contains 'Group') {
			Test-LdsGroup @ldsParam -Delete:$Delete
		}
		if ($Options -contains 'User') {
			Test-LdsUser @ldsParam -Delete:$Delete
		}
		if ($Options -contains 'GroupMembership') {
			Test-LdsGroupMembership @ldsParam -Delete:$Delete
		}
		if ($Options -contains 'AccessRule') {
			Test-LdsAccessRule @ldsParam -Delete:$Delete
		}
	}
}