function New-Change {
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