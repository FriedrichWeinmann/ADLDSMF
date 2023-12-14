function Import-LdsConfiguration {
	<#
	.SYNOPSIS
		Import a set of configuration files.
	
	.DESCRIPTION
		Import a set of configuration files.
		Each configuration file must be a psd1, json or (at PS7+) jsonc file.
		They can be stored any levels of nested folder deep, but they cannot be hidden.

		Each file shall contain an array of entries and each entry shall have an objectclass plus all the attributes it should have.
		Note to include everything an object of the given type must have.
		For each entry, specifying an objectclass is optional: If none is specified, the name of the parent folder is chosen instead.
		Thus, creating a folder named "user" will have all settings directly within default to the objectclass "user".

		Supported Object Classes:
		- AccessRule
		- Group
		- GroupMembership
		- OrganizationalUnit
		- SchemaAttribute
		- User

		Note: Group Memberships and access rules are not really object entities in AD LDS, but are treated the same for configuration purposes.

		Example Content:

		> user.psd1

		@{
			Name = 'Thomas'
			Path = 'OU=Admin,%DomainDN%'
			Enabled = $true
		}
	
	.PARAMETER Path
		Path to a folder containing all configuration sets.
	
	.EXAMPLE
		PS C:\> Import-LdsConfiguration -Path C:\scripts\lds\config

		Imports all the configuration files under the specified path, no matter how deeply nested.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Path
	)

	$objectClasses = 'AccessRule', 'Group', 'GroupMembership', 'OrganizationalUnit', 'SchemaAttribute', 'User'
	$extensions = '.json', '.psd1'
	if ($PSVersionTable.PSVersion.Major -ge 7) {$extensions = '.json', '.jsonc', '.psd1'}

	foreach ($file in Get-ChildItem -Path $Path -Recurse -File | Where-Object Extension -In $extensions) {
		$datasets = Import-PSFPowerShellDataFile -LiteralPath $file.FullName -Psd1Mode Unsafe
		$defaultObjectClass = $file.Directory.Name.ToLower()

		foreach ($dataset in $datasets) {
			if (-not $dataset.ObjectClass) { $dataset.ObjectClass = $defaultObjectClass }

			switch ($dataset.ObjectClass) {
				'groupmembership' {
					$identity = "$($dataset.Group)|$($dataset.Member)|$($dataset.Type)"
					$script:content.groupmembership.$identity = $dataset
				}
				'accessrule' {
					$identity = "$($dataset.Path)|$($dataset.Identity)|$($dataset.IdentityType)|$($dataset.Rights)|$($dataset.ObjectType)"
					$script:content.accessrule.$identity = $dataset
				}
				'SchemaAttribute' {
					$script:content.SchemaAttribute[$dataSet.AttributeID] = $dataSet
				}
				default {
					if ($dataset.ObjectClass -notin $objectClasses) {
						Write-PSFMessage -Level Warning -Message 'Invalid Object Class: {0} Importing file "{1}". Legal Values: {2}' -StringValues $dataset.ObjectClass, $file.FullName, ($objectClasses -join ', ') -Tag 'badClass' -Target $dataset
					}
					$identity = "$($dataset.Name),$($dataset.Path)"
					if (-not $script:content.$($dataset.ObjectClass)) {
						$script:content.$($dataset.ObjectClass) = @{ }
					}
					$script:content.$($dataset.ObjectClass)[$identity] = $dataset
				}
			}
		}
	}
}