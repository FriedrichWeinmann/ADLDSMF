function Reset-LdsAccountPassword {
	<#
	.SYNOPSIS
		Reset the password of any given user account.
	
	.DESCRIPTION
		Reset the password of any given user account.
		The new password will be pasted to clipboard.
	
	.PARAMETER UserName
		Name of the user to reset.
	
	.PARAMETER Server
		LDS Server to contact.
	
	.PARAMETER Partition
		Partition of the LDS Server to search.

	.PARAMETER NewPassword
		The new password to assign.
		Autogenerates a random password if not specified.
	
	.PARAMETER Credential
		Credential to use for the request
	
	.EXAMPLE
		PS C:\> Reset-LdsAccountPassword -Name svc_whatever -Server lds1.contoso.com -Partition 'DC=fabrikam,DC=org'
		
		Resets the password of account 'svc_whatever'
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$UserName,

		[Parameter(Mandatory = $true)]
		[string]
		$Server,

		[Parameter(Mandatory = $true)]
		[string]
		$Partition,

		[SecureString]
		$NewPassword = (New-Password -AsSecureString),

		[PSCredential]
		$Credential
	)

	$ldsParam = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Partition, Credential
	$ldsParamLight = $ldsParam | ConvertTo-PSFHashtable -Exclude Partition
	$userObject = Get-ADUser @ldsParamLight -LDAPFilter "(name=$UserName)" -SearchBase $Partition
	if (-not $userObject) {
		Stop-PSFFunction -Cmdlet $PSCmdlet -Message "Unable to find $UserName!" -EnableException $true
	}

	if (1 -lt @($userObject).Count) {
		Stop-PSFFunction -Cmdlet $PSCmdlet -Message "More than one account found for $UserName!`n$($userObject.DistinguishedName -join "`n")" -EnableException $true
	}

	Set-ADAccountPassword @ldsParam -NewPassword $NewPassword -Identity $userObject.ObjectGUID

	if (-not $userObject.Enabled) {
		Write-PSFMessage -Level Host -Message "Enabling account: $($userObject.Name)"
		Enable-ADAccount @ldsParam -Identity $userObject.ObjectGuid
	}

	Write-PSFMessage -Level Host -Message "Password reset for $($userObject.Name) executed."
	$null = Read-Host "Press enter to paste the new password to the clipboard."
	$cred = [PSCredential]::new("whatever", $NewPassword)
	$cred.GetNetworkCredential().Password | Set-Clipboard
	Write-PSFMessage -Level Host -Message "Password for $($userObject.Name) has been written to clipboard."
}