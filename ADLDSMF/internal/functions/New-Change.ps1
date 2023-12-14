function New-Change {
	<#
	.SYNOPSIS
		Create a new change object.
	
	.DESCRIPTION
		Create a new change object.
		Helper command that unifies result generation.
	
	.PARAMETER Identity
		The identity the change applies to.
	
	.PARAMETER Property
		What property is being modified.
	
	.PARAMETER OldValue
		The old value that is being updated.
	
	.PARAMETER NewValue
		The new value that will be set instead.
	
	.PARAMETER DisplayStyle
		How the change will display in text form.
		Defaults to: NewValue
	
	.PARAMETER Data
		Additional data to include in the change.
	
	.EXAMPLE
		PS C:\> New-Change -Identity "CN=max,OU=Users,DC=Fabrikam,DC=org" Property LuckyNumber -OldValue 1 -NewValue 42

		Creates a new change.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Identity,
		
		[Parameter(Mandatory = $true)]
		[string]
		$Property,

		[AllowEmptyCollection()]
		[AllowNull()]
		$OldValue,

		[AllowEmptyCollection()]
		[AllowNull()]
		$NewValue,

		[ValidateSet('NewValue', 'RemoveValue')]
		[string]
		$DisplayStyle = 'NewValue',

		[AllowEmptyCollection()]
		[AllowNull()]
		$Data
	)

	$dsStyles = @{
		'NewValue'    = {
			'{0} -> {1}' -f $this.Property, $this.New
		}
		'RemoveValue' = {
			'{0} Remove {1}' -f $this.Property, $this.Old
		}
	}

	$object = [PSCustomObject]@{
		PSTypeName = 'AdLds.Change'
		Identity   = $Identity
		Property   = $Property
		Old        = $OldValue
		New        = $NewValue
		Data       = $Data
	}
	Add-Member -InputObject $object -MemberType ScriptMethod -Name ToString -Value $dsStyles[$DisplayStyle] -Force
	$object
}