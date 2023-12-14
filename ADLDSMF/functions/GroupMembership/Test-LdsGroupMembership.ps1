function Test-LdsGroupMembership {
	<#
	.SYNOPSIS
		Test whether the group memberships are in their desired state.
	
	.DESCRIPTION
		Test whether the group memberships are in their desired state.
	
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
		PS C:\> Test-LdsGroupMembership -Server lds1.contoso.com -Partition 'DC=fabrikam,DC=org'
		
		Test whether the group memberships are in their desired state for 'DC=fabrikam,DC=org' on lds1.contoso.com
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
		Update-LdsConfiguration -LdsServer $Server -LdsPartition $Partition
		$ldsParam = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Partition, Credential
		$ldsParamLight = $ldsParam | ConvertTo-PSFHashtable -Remap @{ Partition = 'SearchBase' }

		$members = @{ }
		$ldsObjects = @{ }
	}
	process {
		foreach ($configurationSets in $script:content.groupmembership.Values | Group-Object { $_.Group }) {
			Write-PSFMessage -Level Verbose -Message "Processing group memberships of {0}" -StringValues $configurationSets.Name
			$groupObject = Get-ADGroup @ldsParamLight -LDAPFilter "(name=$($configurationSets.Name))" -Properties *
			if (-not $groupObject) {
				Write-PSFMessage -Level Warning -Message "Group not found: {0}! Cannot process members" -StringValues  $configurationSets.Name
				continue
			}
			$ldsObjects[$groupObject.DistinguishedName] = $groupObject

			#region Determine intended members
			$intendedMembers = foreach ($entry in $configurationSets.Group) {
				# Read from Cache
				if ($members["$($entry.Type):$($entry.Member)"]) {
					$members["$($entry.Type):$($entry.Member)"]
					continue
				}

				# Read from LDS Instance
				$ldsObject = Get-ADObject @ldsParamLight -LDAPFilter "(&(objectClass=$($entry.Type))(name=$($entry.Member)))" -Properties *
				
				# Not Yet Created
				if (-not $ldsObject) {
					Write-PSFMessage -Level Warning -Message 'Unable to find {0} {1}, will be unable to add it to group {2}' -StringValues $entry.Type, $entry.Member, $entry.Group
					continue
				}

				$members["$($entry.Type):$($entry.Member)"] = $ldsObject
				$ldsObjects[$ldsObject.DistinguishedName] = $ldsObject
				$ldsObject
			}
			#endregion Determine intended members

			#region Determine actual members
			$actualMembers = foreach ($member in $groupObject.Members) {
				if ($ldsObjects[$member]) {
					$ldsObjects[$member]
					continue
				}

				try { $ldsObject = Get-ADObject @ldsParam -Identity $member -Properties * -ErrorAction Stop }
				catch {
					Write-PSFMessage -Level Warning -Message "Error resolving member of {0}: {1}" -StringValues $configurationSets.Name, $member -ErrorRecord $_
					continue
				}
				$ldsObjects[$ldsObject.DistinguishedName] = $ldsObject
				$ldsObject
			}
			#endregion Determine actual members
		
			#region Compare and generate changes
			$toAdd = $intendedMembers | Where-Object DistinguishedName -NotIn $actualMembers.DistinguishedName | ForEach-Object {
				[PSCustomObject]@{
					PSTypename = 'AdLdsTools.Change.GroupMembership'
					Action     = 'Add'
					Member     = $_.Name
					Type       = $_.ObjectClass
					DN         = $_.DistinguishedName
					Group      = $configurationSets.Name
				}
			}
			if ($Delete) { $toAdd = @() }

			$toRemove = $actualMembers | Where-Object {
				(-not $Delete -and $_.DistinguishedName -NotIn $intendedMembers.DistinguishedName) -or
				($Delete -and $_.DistinguishedName -in $intendedMembers.DistinguishedName)
			} | ForEach-Object {
				[PSCustomObject]@{
					PSTypename = 'AdLdsTools.Change.GroupMembership'
					Action     = 'Remove'
					Member     = $_.Name
					Type       = $_.ObjectClass
					DN         = $_.DistinguishedName
					Group      = $configurationSets.Name
				}
			}

			$changes = @($toAdd) + @($toRemove) | Remove-PSFNull | Add-Member -MemberType ScriptMethod -Name ToString -Value {
				'{0} -> {1}' -f $this.Action, $this.Member
			} -Force -PassThru
			#endregion Compare and generate changes

			if ($changes) {
				New-TestResult -Type GroupMemberShip -Action Update -Identity $groupObject.Name -ADObject $groupObject -Configuration $configurationSets -Change $changes
			}
		}
	}
}