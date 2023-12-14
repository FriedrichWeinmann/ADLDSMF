<#
Inheritance:
- None: None/None
- All: ContainerInherit/None
- Descendents
- SelfAndChildren
- Children
#>

@{
	Path = '%DomainDN%'
	Identity = 'AllUsers'
	IdentityType = 'Group'
	Rights = 'Enumerate'
	Type = 'Allow'
}
@{
	Path = 'OU=Nodes,%DomainDN%'
	Identity = 'AllUsers'
	IdentityType = 'Group'
	Rights = 'Read'
	Inheritance = 'All'
	Type = 'Allow'
}