function Test-LdsGroup {
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
		$systemProperties = 'ObjectClass', 'Path', 'Name'
	}
	process {
		foreach ($configurationItem in $script:content.group.Values) {
			$path = 'CN={0},{1}' -f $configurationItem.Name, ($configurationItem.Path -replace '%DomainDN%',$Partition)
			if ($path -notmatch ',DC=') { $path = $path, $Partition -join ',' }

			$resultDefaults = @{
				Type = 'Group'
				Identity = $path
				Configuration = $configurationItem	
			}

			$failed = $null
			$adObject = $null
			try { $adObject = Get-ADGroup @ldsParam -Identity $path -Properties * -ErrorAction SilentlyContinue -ErrorVariable failed }
			catch { $failed = $_ }
			if ($failed -and $failed.CategoryInfo.Category -ne 'ObjectNotFound') {
				foreach ($failure in $failed) { Write-Error $failure }
				continue
			}

			#region Cases
			# Case: Does not Exist
			if (-not $adObject) {
				if ($Delete) { continue }

				New-TestResult @resultDefaults -Action Create
				continue
			}

			# Case: Exists
			$resultDefaults.ADObject = $adObject
			if ($Delete) {
				New-TestResult @resultDefaults -Action Delete
				continue
			}

			$changes = foreach ($pair in $configurationItem.GetEnumerator()) {
				if ($pair.Key -in $systemProperties) { continue }
				if ($pair.Value -ne $adObject.$($pair.Key)) {
					New-Change -Identity $path -Property $pair.Key -OldValue $adObject.$($pair.Key) -NewValue $pair.Value
				}
			}

			if ($changes) {
				New-TestResult @resultDefaults -Action Update -Change $changes
			}
			#endregion Cases
		}
	}
}