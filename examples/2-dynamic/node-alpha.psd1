# Parameters
$ouRoot = 'Alpha'
$serviceUser = 'svc.alpha'

# OUs
@{
	Name        = "$ouRoot"
	Path        = 'OU=Nodes,%DomainDN%'
	ObjectClass = 'organizationalUnit'
}
@{
	Name        = 'Users'
	Path        = "OU=$ouRoot,OU=Nodes,%DomainDN%"
	ObjectClass = 'organizationalUnit'
}
@{
	Name        = 'Groups'
	Path        = "OU=$ouRoot,OU=Nodes,%DomainDN%"
	ObjectClass = 'organizationalUnit'
}

# Users
@{
	Name        = $serviceUser
	Path        = 'OU=Users,OU=Admin,%DomainDN%'
	Enabled     = $true
	ObjectClass = 'user'
}

# Group Membership
@{
	Group       = 'AllUsers'
	Member      = $serviceUser
	Type        = 'user'
	ObjectClass = 'groupmemberships'
}

# Access Rules
# Allow Creating, Deleting objects
@{
	Path = 'OU=Alpha,OU=Nodes,%DomainDN%'
	Identity = $serviceUser
	IdentityType = 'User'
	Rights = 'ManageChildren'
	Inheritance = 'Descendents'
	# Type = 'Allow'
}

# Allow Modifying existing objects
@{
	Path = 'OU=Alpha,OU=Nodes,%DomainDN%'
	Identity = $serviceUser
	IdentityType = 'User'
	Rights = 'EditObject'
	Inheritance = 'Descendents'
	# Type = 'Allow'
}
