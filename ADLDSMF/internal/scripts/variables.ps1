$script:content = @{
	user               = @{ }
	group              = @{ }
	organizationalUnit = @{ }
	groupmembership    = @{ }
	accessrule         = @{ }
	SchemaAttribute    = @{ }
}

$script:adrights = @{
	'FullControl'    = @(
		[System.DirectoryServices.ActiveDirectoryRights]::GenericAll
	)
	'Enumerate'      = @(
		[System.DirectoryServices.ActiveDirectoryRights]::ListChildren
		[System.DirectoryServices.ActiveDirectoryRights]::ListObject
	)
	'Read'           = @(
		[System.DirectoryServices.ActiveDirectoryRights]::GenericRead
	)
	'EditObject'     = @(
		[System.DirectoryServices.ActiveDirectoryRights]::Delete
		[System.DirectoryServices.ActiveDirectoryRights]::ReadProperty
		[System.DirectoryServices.ActiveDirectoryRights]::WriteProperty
	)
	'ManageChildren' = @(
		[System.DirectoryServices.ActiveDirectoryRights]::CreateChild
		[System.DirectoryServices.ActiveDirectoryRights]::DeleteChild
	)
	'Extended'       = @(
		[System.DirectoryServices.ActiveDirectoryRights]::ExtendedRight
	)
}