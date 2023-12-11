function New-TestResult {
	[CmdletBinding()]
	param (
		[string]
		$Type,

		[ValidateSet('Create', 'Update', 'Delete', 'Add', 'Remove', 'Rename')]
		[string]
		$Action,

		[string]
		$Identity,

		$Change,

		$ADObject,

		$Configuration
	)

	[PSCustomObject]@{
		PSTypeName    = 'AdLds.Testresult'
		Type          = $Type
		Action        = $Action
		Identity      = $Identity
		Change        = $Change
		ADObject      = $ADObject
		Configuration = $Configuration
	}
}