function Unprotect-OrganizationalUnit {
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