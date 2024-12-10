@{
	Path = '%DomainDN%'
	Identity = 'Administrators'
	IdentityType = 'Group'
	Rights = 'FullControl'
	Type = 'Allow'
    Inheritance = 'All'
}
@{
	Path = '%DomainDN%'
	Identity = 'Readers'
	IdentityType = 'Group'
	Rights = 'Read'
	Type = 'Allow'
    Inheritance = 'All'
}

# SID will need to be updated per instance
@{
	Path = '%DomainDN%'
	Identity = 'S-1-413601087-3431389616-518'
	IdentityType = 'SID'
	Rights = 'Read'
	Type = 'Allow'
}
@{
	Path = '%DomainDN%'
	Identity = 'S-1-413601087-3431389616-518'
	IdentityType = 'SID'
	Rights = 'Extended'
	ObjectType = '1131f6aa-9c07-11d1-f79f-00c04fc2dcd2'
	Type = 'Allow'
}
@{
	Path = '%DomainDN%'
	Identity = 'S-1-413601087-3431389616-518'
	IdentityType = 'SID'
	Rights = 'Extended'
	ObjectType = '1131f6ab-9c07-11d1-f79f-00c04fc2dcd2'
	Type = 'Allow'
}
@{
	Path = '%DomainDN%'
	Identity = 'S-1-413601087-3431389616-518'
	IdentityType = 'SID'
	Rights = 'Extended'
	ObjectType = '1131f6ac-9c07-11d1-f79f-00c04fc2dcd2'
	Type = 'Allow'
}
@{
	Path = '%DomainDN%'
	Identity = 'S-1-413601087-3431389616-518'
	IdentityType = 'SID'
	Rights = 'Extended'
	ObjectType = '1131f6ad-9c07-11d1-f79f-00c04fc2dcd2'
	Type = 'Allow'
}