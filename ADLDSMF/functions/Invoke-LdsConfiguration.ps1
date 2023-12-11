function Invoke-LdsConfiguration {
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