@{
	Name        = 'Nodes'
	Path        = '%DomainDN%'
	Description = 'Base OU for GAL Sync content'
}
@{
	Name        = 'Admin'
	Path        = '%DomainDN%'
	Description = 'Administrative Content'
}
@{
	Name        = 'Users'
	Path        = 'OU=Admin,%DomainDN%'
	Description = 'Admin Users'
}