function Resolve-SchemaGuid {
	<#
	.SYNOPSIS
		Resolves the name of an attribute or objectclass to its GUID form.
	
	.DESCRIPTION
		Resolves the name of an attribute or objectclass to its GUID form.
		Used to enable user-friendly names in configuration.

		+ Supports caching requests to optimize performance
		+ Will return guids unmodified
	
	.PARAMETER Name
		The name or guid of the attribute or object class.
		Guids will be returned unverified.
	
	.PARAMETER Server
		The LDS Server to connect to.

	.PARAMETER Credential
		The credentials - if any - to use to the specified server.
	
	.PARAMETER Cache
		A hashtable used for caching requests.
	
	.EXAMPLE
		PS C:\> Resolve-SchemaGuid -Name contact -Server lds1.contoso.com -Cache $cache
		
		Returns the GUID form of the "contact" object class if present.
	#>
	[OutputType([string])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[string]
		$Name,

		[Parameter(Mandatory = $true)]
		[string]
		$Server,

		[PSCredential]
		$Credential,

		[hashtable]
		$Cache = @{ }
	)

	begin {
		$ldsParam = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
	}
	process {
		if ($Name -as [Guid]) {
			return $Name
		}

		if ($Cache[$Name]) {
			return $Cache[$Name]
		}

		$rootDSE = [adsi]"LDAP://$Server/rootDSE"
		$targetObjectClassObj = Get-ADObject @ldsParam -SearchBase ($rootdse.schemaNamingContext.value) -LDAPFilter "CN=$Name" -Properties 'schemaIDGUID'
		if (-not $targetObjectClassObj) {
			throw "Unknown attribute or object class: $Name"
		}
	
		$bytes = [byte[]]$targetObjectClassObj.schemaIDGUID
		$guid = [guid]::new($bytes)
		$Cache[$Name] = "$guid"

		"$guid"
	}
}