function Unprotect-OrganizationalUnit {
	<#
	.SYNOPSIS
		Removes deny rules on OrganizationalUnits.
	
	.DESCRIPTION
		Removes deny rules on OrganizationalUnits.
		Necessary whenever we want to delete an OU.
	
	.PARAMETER Server
		The LDS Server to target.
	
	.PARAMETER Partition
		The Partition on the LDS Server to target.
	
	.PARAMETER Credential
		Credentials to use for the operation.
	
	.PARAMETER Identity
		The OU to unprotect.
		Specify the full distinguishedname.
	
	.EXAMPLE
		PS C:\> Unprotect-OrganizationalUnit @ldsParam -Identity $ouPath
		
		Removes the deletion protection from the OU specified in $ouPath
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
		$Credential,

		[Parameter(Mandatory = $true)]
		[string]
		$Identity
	)

	begin {
		Update-ADSec
		$ldsParam = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
	}

	process {
		$adObject = Get-ADObject @ldsParam -Identity $Identity -Partition $Partition -Properties DistinguishedName

		$acl = Get-AdsAcl @ldsParam -Path $adObject.DistinguishedName
		$denyRules = $acl.Access | Where-Object AccessControlType -eq Deny
		if (-not $denyRules) { return }

		foreach ($rule in $denyRules) {
			$null = $acl.RemoveAccessRule($rule)
		}
		$acl | Set-AdsAcl @ldsParam -Path $adObject.DistinguishedName
	}
}