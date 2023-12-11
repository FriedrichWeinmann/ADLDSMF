function Reset-LdsConfiguration {
	[CmdletBinding()]
	param ()

	$script:content = @{
		user               = @{ }
		group              = @{ }
		organizationalUnit = @{ }
		groupmemberships   = @{ }
		accessrules        = @{ }
		SchemaAttributes   = @{ }
	}
}