@{
	# Script module or binary module file associated with this manifest
	RootModule        = 'ADLDSMF.psm1'
	
	# Version number of this module.
	ModuleVersion     = '1.0.0'
	
	# ID used to uniquely identify this module
	GUID              = '4152b344-748f-43f4-9982-e0f0bec21185'
	
	# Author of this module
	Author            = 'Friedrich Weinmann'
	
	# Company or vendor of this module
	CompanyName       = ' '
	
	# Copyright statement for this module
	Copyright         = 'Copyright (c) 2023 Friedrich Weinmann'
	
	# Description of the functionality provided by this module
	Description       = 'Provisions the content of AD LDS instances'
	
	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '5.1'
	
	# Modules that must be imported into the global environment prior to importing
	# this module
	RequiredModules   = @(
		@{ ModuleName = 'PSFramework'; ModuleVersion = '1.12.346' }
		@{ ModuleName = 'ADSec'; ModuleVersion = '1.0.1' }
	)
	
	# Assemblies that must be loaded prior to importing this module
	# RequiredAssemblies = @('bin\ADLDSMF.dll')
	
	# Type files (.ps1xml) to be loaded when importing this module
	# TypesToProcess = @('xml\ADLDSMF.Types.ps1xml')
	
	# Format files (.ps1xml) to be loaded when importing this module
	FormatsToProcess  = @('xml\ADLDSMF.Format.ps1xml')
	
	# Functions to export from this module
	FunctionsToExport = @(
		'Get-LdsDomain'
		'Import-LdsConfiguration'
		'Invoke-LdsAccessRule'
		'Invoke-LdsConfiguration'
		'Invoke-LdsGroup'
		'Invoke-LdsGroupMembership'
		'Invoke-LdsOrganizationalUnit'
		'Invoke-LdsSchemaAttribute'
		'Invoke-LdsUser'
		'Reset-LdsAccountPassword'
		'Reset-LdsConfiguration'
		'Test-LdsAccessRule'
		'Test-LdsConfiguration'
		'Test-LdsGroup'
		'Test-LdsGroupMembership'
		'Test-LdsOrganizationalUnit'
		'Test-LdsSchemaAttribute'
		'Test-LdsUser'
	)
	
	# Cmdlets to export from this module
	CmdletsToExport   = @()
	
	# Variables to export from this module
	VariablesToExport = @()
	
	# Aliases to export from this module
	AliasesToExport   = @()
	
	# List of all modules packaged with this module
	ModuleList        = @()
	
	# List of all files packaged with this module
	FileList          = @()
	
	# Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData       = @{
		
		#Support for PowerShellGet galleries.
		PSData = @{
			
			# Tags applied to this module. These help with module discovery in online galleries.
			Tags = @('ldap','adlds')
			
			# A URL to the license for this module.
			LicenseUri = 'https://github.com/FriedrichWeinmann/ADLDSMF/blob/master/LICENSE'
			
			# A URL to the main website for this project.
			ProjectUri = 'https://github.com/FriedrichWeinmann/ADLDSMF'
			
			# A URL to an icon representing this module.
			# IconUri = ''
			
			# ReleaseNotes of this module
			ReleaseNotes = 'https://github.com/FriedrichWeinmann/ADLDSMF/blob/master/ADLDSMF/changelog.md'
			
		} # End of PSData hashtable
		
	} # End of PrivateData hashtable
}