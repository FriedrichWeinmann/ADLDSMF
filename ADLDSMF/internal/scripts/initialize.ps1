# Make ACL work again
$null = Get-Acl -Path . -ErrorAction Ignore

# Disable AD Connection Check
Set-PSFConfig -FullName 'ADSec.Connect.NoAssertion' -Value $true

# Load config if present
if (Test-Path -Path "$script:ModuleRoot\Config") {
	Import-LdsConfiguration -Path "$script:ModuleRoot\Config"
}