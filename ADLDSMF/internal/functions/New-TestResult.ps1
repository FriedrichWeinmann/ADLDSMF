function New-TestResult {
	<#
	.SYNOPSIS
		A new test result, as produced by any of the test commands.
	
	.DESCRIPTION
		A new test result, as produced by any of the test commands.
		This helper function ensures that all test results look the same.
	
	.PARAMETER Type
		What kind object is being tested.
		Should receive the objectclass being affected.
	
	.PARAMETER Action
		What we do with the object in question.
	
	.PARAMETER Identity
		The specific object being changed.
	
	.PARAMETER Change
		Any specific change data that will be applied to the object.
		See New-Change for more details on that structure.
	
	.PARAMETER ADObject
		The actual AD LDS Object being modified.
		Will usually be $null when creating something new.
	
	.PARAMETER Configuration
		The configuration object based on which the change will be applied.
	
	.EXAMPLE
		PS C:\> New-TestResult -Type User -Action Create -Identity $userName -Configuration $configSet
		
		Test result heralding the creation of a new user.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
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