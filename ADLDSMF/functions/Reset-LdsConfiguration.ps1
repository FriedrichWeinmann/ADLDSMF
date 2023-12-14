function Reset-LdsConfiguration {
	<#
	.SYNOPSIS
		Removes all registered configuration settings.
	
	.DESCRIPTION
		Removes all registered configuration settings.
	
	.EXAMPLE
		PS C:\> Reset-LdsConfiguration
		
		Removes all registered configuration settings.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param ()

	$script:content = @{
		user               = @{ }
		group              = @{ }
		organizationalUnit = @{ }
		groupmembership    = @{ }
		accessrule         = @{ }
		SchemaAttribute    = @{ }
	}
}