function Test-LdsAccessRule {
	<#
	.SYNOPSIS
		Tests, whether the current access rules match the configured state.
	
	.DESCRIPTION
		Tests, whether the current access rules match the configured state.
	
	.PARAMETER Server
		The LDS Server to target.
	
	.PARAMETER Partition
		The Partition on the LDS Server to target.
	
	.PARAMETER Credential
		Credentials to use for the operation.
	
	.PARAMETER Delete
		Undo everything defined in configuration.
		Allows rolling back after deployment.
	
	.EXAMPLE
		PS C:\> Test-LdsAccessRule -Server lds1.contoso.com -Partition 'DC=fabrikam,DC=org'

		Tests, whether the current access rules on lds1.contoso.com match the configured state.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Server,

		[Parameter(Mandatory = $true)]
		[string]
		$Partition,

		[PSCredential]
		$Credential,

		[switch]
		$Delete
	)
	
	begin {
		#region Functions
		function Resolve-AccessRule {
			[OutputType([System.DirectoryServices.ActiveDirectoryAccessRule])]
			[CmdletBinding()]
			param (
				[Parameter(Mandatory = $true)]
				$RuleCfg,

				[Parameter(Mandatory = $true)]
				[string]
				$Server,

				[Parameter(Mandatory = $true)]
				[string]
				$Partition,

				[PSCredential]
				$Credential,

				[hashtable]
				$SchemaCache = @{ },

				[hashtable]
				$PrincipalCache = @{ },

				[string]
				$DomainSID
			)

			$ldsParam = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential

			$rights = $script:adrights[$RuleCfg.Rights]
			
			# resolve AccessRule settings
			$inheritanceType = 'None'
			if ($RuleCfg.Inheritance) {
				$inheritanceType = $RuleCfg.Inheritance
			}
			$objectType = [guid]::Empty
			$inheritedObjectType = [guid]::Empty
			if ($RuleCfg.ObjectType) { $objectType = $RuleCfg.ObjectType | Resolve-SchemaGuid @ldsParam -Cache $SchemaCache }
			if ($RuleCfg.InheritedObjectType) { $inheritedObjectType = $RuleCfg.InheritedObjectType | Resolve-SchemaGuid @ldsParam -Cache $SchemaCache }
			$type = 'Allow'
			if ($RuleCfg.Type) { $type = $RuleCfg.Type }

			$principal = $PrincipalCache["$($RuleCfg.IdentityType):$($RuleCfg.Identity)"]
			if (-not $principal -and 'SID' -eq $RuleCfg.IdentityType){
				$ruleIdentity = $RuleCfg.Identity -replace '%DomainSID%', $DomainSID
				$sid = $ruleIdentity -as [System.Security.Principal.SecurityIdentifier]
				if (-not $sid) {
					throw "Principal is not a legal SID: $($RuleCfg.Identity)!"
				}
				$PrincipalCache["$($RuleCfg.IdentityType):$($RuleCfg.Identity)"] = $sid
				$principal = $PrincipalCache["$($RuleCfg.IdentityType):$($RuleCfg.Identity)"]
			}
			elseif (-not $principal) {
				$principalObject = Get-ADObject @ldsParam -SearchBase $Partition -LDAPFilter "(&(objectClass=$($RuleCfg.IdentityType))(name=$($RuleCfg.Identity)))" -Properties ObjectSID -ErrorAction Stop
				if (-not $principalObject) {
					throw "Principal not found: $($RuleCfg.IdentityType) - $($RuleCfg.Identity)"
				}

				$PrincipalCache["$($RuleCfg.IdentityType):$($RuleCfg.Identity)"] = $principalObject.ObjectSID
				$principal = $PrincipalCache["$($RuleCfg.IdentityType):$($RuleCfg.Identity)"]
			}

			[System.DirectoryServices.ActiveDirectoryAccessRule]::new(
				$principal,
				$rights,
				$type,
				$objectType,
				$inheritanceType,
				$inheritedObjectType
			)
		}
		
		function Compare-AccessRule {
			[CmdletBinding()]
			param (
				[Parameter(Mandatory = $true)]
				[System.DirectoryServices.ActiveDirectoryAccessRule[]]
				$Reference,

				[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
				$InputObject,

				[switch]
				$NoMatch
			)

			process {
				if (-not $InputObject) { return }


				$isMatched = $false

				foreach ($referenceObject in $Reference) {
					if ($referenceObject.ActiveDirectoryRights -bxor $InputObject.ActiveDirectoryRights) { continue }
					if ($referenceObject.InheritanceType -ne $InputObject.InheritanceType) { continue }
					if ($referenceObject.ObjectType -ne $InputObject.ObjectType) { continue }
					if ($referenceObject.InheritedObjectType -ne $InputObject.InheritedObjectType) { continue }
					if ($referenceObject.AccessControlType -ne $InputObject.AccessControlType) { continue }
					if ("$($referenceObject.IdentityReference)" -ne "$($InputObject.IdentityReference)") { continue }

					$isMatched = $true
					break
				}

				if ($isMatched -eq -not $NoMatch) {
					$InputObject
				}
			}
		}

		function Get-ObjectDefaultRule {
			[CmdletBinding()]
			param (
				[string]
				$Path,

				[hashtable]
				$LdsParam,

				[hashtable]
				$LdsParamLight,

				$RootDSE,

				[hashtable]
				$DefaultPermissions
			)

			$adObject = Get-ADObject @LdsParam -Identity $Path -Properties ObjectClass
			if ($DefaultPermissions.ContainsKey($adObject.ObjectClass)) {
				return $DefaultPermissions[$adObject.ObjectClass]
			}

			$class = Get-ADObject @ldsParamLight -SearchBase $RootDSE.schemaNamingContext -LDAPFilter "(&(objectClass=classSchema)(ldapDisplayName=$($adObject.ObjectClass)))" -Properties defaultSecurityDescriptor
			$acl = [System.DirectoryServices.ActiveDirectorySecurity]::new()
			$acl.SetSecurityDescriptorSddlForm($class.defaultSecurityDescriptor)
			$DefaultPermissions[$adObject.ObjectClass] = $acl.GetAccessRules($true, $false, [System.Security.Principal.SecurityIdentifier])
			$DefaultPermissions[$adObject.ObjectClass]
		}
		#endregion Functions

		Update-ADSec
		Update-LdsConfiguration -LdsServer $Server -LdsPartition $Partition
		$ldsParam = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Partition, Credential
		$ldsParamLight = $ldsParam | ConvertTo-PSFHashtable -Exclude Partition
		$rootDSE = Get-ADRootDSE @ldsParamLight
		$domainSID = (Get-ADObject @ldsParamLight -LDAPFilter '(&(objectCategory=group)(name=Administrators))' -SearchBase $ldsParam.Partition -Properties objectSID).ObjectSID.Value -replace '-512$'

		$principals = @{ }
		$schemaCache = @{ }
		$pathCache = @{ }
	}
	process {
		#region Adding
		foreach ($ruleCfg in $script:content.accessrule.Values) {
			$resolvedPath = $ruleCfg.Path -replace '%DomainDN%', $Partition
			try { $rule = Resolve-AccessRule @ldsParam -RuleCfg $ruleCfg -SchemaCache $schemaCache -PrincipalCache $principals -DomainSID $domainSID }
			catch {
				Write-PSFMessage -Level Warning -Message "Failed to process rule for $resolvedPath, granting $($ruleCfg.Rights) to $($ruleCfg.Identity)" -ErrorRecord $_
				continue
			}
			if (-not $pathCache[$resolvedPath]) { $pathCache[$resolvedPath] = @($rule) }
			else { $pathCache[$resolvedPath] = @($pathCache[$resolvedPath]) + @($rule) }

			$acl = Get-AdsAcl @ldsParamLight -Path $resolvedPath
			$currentRules = $acl.GetAccessRules($true, $false, [System.Security.Principal.SecurityIdentifier])
			$matching = $currentRules | Compare-AccessRule -Reference $rule

			$change = [PSCustomObject]@{
				Path  = $resolvedPath
				Name  = $ruleCfg.Identity
				Right = $ruleCfg.Rights
				Type  = $rule.AccessControlType
				Rule  = $rule
			}
			Add-Member -InputObject $change -MemberType ScriptMethod -Name ToString -Force -Value {
				if ('Allow' -eq $this.Type) { '{0} -> {1}' -f $this.Name, $this.Right }
				else { '{0} != {1}' -f $this.Name, $this.Right }
			}

			if ($matching) {
				if ($Delete) {
					$change.Rule = $matching
					New-TestResult -Type AccessRule -Action Remove -Identity $resolvedPath -Configuration $ruleCfg -ADObject $acl -Change $change
				}
				continue
			}
			if ($Delete) { continue }

			New-TestResult -Type AccessRule -Action Add -Identity $resolvedPath -Configuration $ruleCfg -ADObject $acl -Change $change
		}
		#endregion Adding

		#region Removing
		$schemaDefaultPermissions = @{ }
		$sidToName = @{ }

		foreach ($adPath in $pathCache.Keys) {
			$defaultRules = Get-ObjectDefaultRule -Path $adPath -LdsParam $ldsParam -LdsParamLight $ldsParamLight -RootDSE $rootDSE -DefaultPermissions $schemaDefaultPermissions
			$intendedRules = @($defaultRules) + @($pathCache[$adPath]) | Remove-PSFNull

			$acl = Get-AdsAcl @ldsParamLight -Path $adPath
			$currentRules = $acl.GetAccessRules($true, $false, [System.Security.Principal.SecurityIdentifier])
			$surplusRules = $currentRules | Compare-AccessRule -Reference $intendedRules -NoMatch

			foreach ($surplusRule in $surplusRules) {
				# Skip OU deletion protection
				if ('S-1-1-0' -eq $surplusRule.IdentityReference -and 'Deny' -eq $surplusRule.AccessControlType) { continue }
				
				if (-not $sidToName[$surplusRule.IdentityReference]) {
					try { $sidToName[$surplusRule.IdentityReference] = Get-ADObject @ldsParamLight -SearchBase $Partition -LDAPFilter "(objectSID=$($surplusRule.IdentityReference))" -Properties Name }
					catch { $sidToName[$surplusRule.IdentityReference] = @{ Name = $surplusRule.IdentityReference }}
					if (-not $sidToName[$surplusRule.IdentityReference]) { $sidToName[$surplusRule.IdentityReference] = @{ Name = $surplusRule.IdentityReference } }
				}
				$change = [PSCustomObject]@{
					Path  = $adPath
					Name  = $sidToName[$surplusRule.IdentityReference].Name
					Right = $surplusRule.ActiveDirectoryRights
					Type  = $surplusRule.AccessControlType
					Rule  = $surplusRule
				}

				Add-Member -InputObject $change -MemberType ScriptMethod -Name ToString -Force -Value {
					if ('Allow' -eq $this.Type) { '{0} -> {1}' -f $this.Name, $this.Right }
					else { '{0} != {1}' -f $this.Name, $this.Right }
				}
	
				New-TestResult -Type AccessRule -Action Remove -Identity $adPath -ADObject $acl -Change $change
			}
		}
		#endregion Removing
	}
}