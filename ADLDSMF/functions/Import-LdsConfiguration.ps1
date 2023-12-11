function Import-LdsConfiguration {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Path
	)

	foreach ($file in Get-ChildItem -Path $Path -Recurse -File | Where-Object Extension -In '.json', '.psd1') {
		$datasets = Import-PSFPowerShellDataFile -LiteralPath $file.FullName -Psd1Mode Unsafe
		$defaultObjectClass = $file.Directory.Name.ToLower()

		foreach ($dataset in $datasets) {
			if (-not $dataset.ObjectClass) { $dataset.ObjectClass = $defaultObjectClass }

			switch ($dataset.ObjectClass) {
				'groupmemberships' {
					$identity = "$($dataset.Group)|$($dataset.Member)|$($dataset.Type)"
					$script:content.groupmemberships.$identity = $dataset
				}
				'accessrules' {
					$identity = "$($dataset.Path)|$($dataset.Identity)|$($dataset.IdentityType)|$($dataset.Rights)|$($dataset.ObjectType)"
					$script:content.accessrules.$identity = $dataset
				}
				'SchemaAttribute' {
					$script:content.SchemaAttributes[$dataSet.AttributeID] = $dataSet
				}
				default {
					$identity = "$($dataset.Name),$($dataset.Path)"
					if (-not $script:content.$($dataset.ObjectClass)) {
						$script:content.$($dataset.ObjectClass) = @{ }
					}
					$script:content.$($dataset.ObjectClass)[$identity] = $dataset
				}
			}
		}
	}
}