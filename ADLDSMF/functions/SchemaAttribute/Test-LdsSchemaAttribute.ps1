function Test-LdsSchemaAttribute {
	<#
	.SYNOPSIS
		Tests, whether the intended schema attributes have been applied.
	
	.DESCRIPTION
		Tests, whether the intended schema attributes have been applied.
	
	.PARAMETER Server
		The LDS Server to target.
	
	.PARAMETER Partition
		The Partition on the LDS Server to target.
	
	.PARAMETER Credential
		Credentials to use for the operation.
	
	.EXAMPLE
		PS C:\> Test-LdsSchemaAttribute -Server lds1.contoso.com -Partition 'DC=fabrikam,DC=org'

		Tests, whether the intended schema attributes have been applied to 'DC=fabrikam,DC=org' on lds1.contoso.com
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Server,

		[Parameter(Mandatory = $true)]
		[string]
		$Partition,

		[PSCredential]
		$Credential
	)

	begin {
		Update-LdsConfiguration -LdsServer $Server -LdsPartition $Partition
		$ldsParam = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Partition, Credential
		$ldsParamLight = $ldsParam | ConvertTo-PSFHashtable -Exclude Partition
		$systemProperties = 'ObjectClass', 'AttributeID', 'IsDeleted', 'Optional', 'MayContain'

		$rootDSE = Get-ADRootDSE @ldsParamLight
		$classes = Get-ADObject @ldsParamLight -SearchBase $rootDSE.schemaNamingContext -LDAPFilter '(objectClass=classSchema)' -Properties mayContain, adminDisplayName
	}
	process {
		foreach ($schemaSetting in $script:content.SchemaAttribute.Values) {
			$schemaObject = $null
			$schemaObject = Get-ADObject @ldsParamLight -LDAPFilter "(attributeID=$($schemaSetting.AttributeID))" -SearchBase $rootDSE.schemaNamingContext -ErrorAction Ignore -Properties *
			$resultDefaults = @{
				Type          = 'SchemaAttribute'
				Identity      = $schemaSetting.AdminDisplayName
				Configuration = $schemaSetting
			}

			if (-not $schemaObject) {
				# If we already want to disable the attribute, no need to create it
				if ($schemaSetting.IsDeleted) { continue }
				if ($schemaSetting.Optional) { continue }

				New-TestResult @resultDefaults -Action Create
				foreach ($entry in $schemaSetting.MayContain) {
					if ($classes.AdminDisplayName -notcontains $entry) { continue }
					New-TestResult @resultDefaults -Action Add -Change @(
						New-Change -Identity $schemaSetting.AdminDisplayName -Property MayContain -NewValue $entry -Data ($classes | Where-Object AdminDisplayName -EQ $entry)
					)
				}
				continue
			}

			$resultDefaults.ADObject = $schemaObject

			if ($schemaSetting.IsDeleted -and -not $schemaObject.isDeleted) {
				New-TestResult @resultDefaults -Action Delete -Change @(
					New-Change -Identity $schemaSetting.AdminDisplayName -Property IsDeleted -OldValue $false -NewValue $true
				)
			}

			if ($schemaSetting.Name -and $schemaSetting.Name -cne $schemaObject.Name) {
				New-TestResult @resultDefaults -Action Rename -Change @(
					New-Change -Identity $schemaSetting.AdminDisplayName -Property Name -OldValue $schemaObject.Name -NewValue $schemaSetting.Name
				)
			}

			$changes = foreach ($pair in $schemaSetting.GetEnumerator()) {
				if ($pair.Key -in $systemProperties) { continue }
				if ($pair.Value -cne $schemaObject.$($pair.Key)) {
					New-Change -Identity $schemaSetting.AdminDisplayName -Property $pair.Key -OldValue $schemaObject.$($pair.Key) -NewValue $pair.Value
				}
			}
			if ($changes) {
				New-TestResult @resultDefaults -Action Update -Change $changes
			}

			$mayBeContainedIn = $schemaSetting.MayContain
			if ($schemaSetting.IsDeleted) { $mayBeContainedIn = @() }

			$classesMatch = $classes | Where-Object mayContain -Contains $schemaObject.LdapDisplayName
			foreach ($matchingclass in $classesMatch) {
				if ($matchingclass.AdminDisplayName -in $mayBeContainedIn) { continue }
				New-TestResult @resultDefaults -Action Remove -Change @(
					New-Change -Identity $schemaSetting.AdminDisplayName -Property MayContain -OldValue $matchingclass.AdminDisplayName -DisplayStyle RemoveValue -Data $matchingClass
				)
			}
			foreach ($allowedClass in $mayBeContainedIn) {
				if ($classesMatch.AdminDisplayName -contains $allowedClass) { continue }
				New-TestResult @resultDefaults -Action Add -Change @(
					New-Change -Identity $schemaSetting.AdminDisplayName -Property MayContain -NewValue $allowedClass -Data ($classes | Where-Object AdminDisplayName -EQ $allowedClass)
				)
			}
		}
	}
}