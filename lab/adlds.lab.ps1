$labname = 'ADLDS'
$domain = 'contoso.com'
$imageUI = 'Windows Server 2022 Datacenter (Desktop Experience)'

New-LabDefinition -Name $labname -DefaultVirtualizationEngine HyperV

$PSDefaultParameterValues['Add-LabMachineDefinition:Memory'] = 2GB
$PSDefaultParameterValues['Add-LabMachineDefinition:OperatingSystem'] = $imageUI
$PSDefaultParameterValues['Add-LabMachineDefinition:DomainName'] = $domain

Add-LabMachineDefinition -Name AdldsDC -Roles RootDC
Add-LabMachineDefinition -Name AdldsAdminHost
Add-LabMachineDefinition -Name AdldsLds

Install-Lab

Install-LabWindowsFeature -ComputerName AdldsAdminHost -FeatureName NET-Framework-Core, NET-Non-HTTP-Activ, GPMC, RSAT-AD-Tools

Invoke-LabCommand -ActivityName "Setting Keyboard Layout" -ComputerName (Get-LabVM).Name -ScriptBlock { Set-WinUserLanguageList -LanguageList 'de-de' -Confirm:$false -Force }

#region Install Software
$sourcesRoot = Get-LabSourcesLocation
$softwarePath = "$sourcesRoot\SoftwarePackages"

$powershell = Get-ChildItem -Path $softwarePath -Filter 'PowerShell-*.msi' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Install-LabSoftwarePackage -Path $powershell.FullName -CommandLine '/quiet' -ComputerName AdldsAdminHost

$vscode = Get-ChildItem -Path $softwarePath -Filter 'VSCodeSetup-x64-*.exe' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Install-LabSoftwarePackage -Path $vscode.FullName -CommandLine '/VERYSILENT /MERGETASKS=!runcode' -ComputerName AdldsAdminHost

$psextension = Get-ChildItem -Path $softwarePath -Filter 'ms-vscode.PowerShell-*.vsix' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Copy-LabFileItem -Path $psextension.FullName -DestinationFolderPath 'C:\install' -ComputerName AdldsAdminHost
#endregion Install Software

#region Install ADLDS
Install-LabWindowsFeature -ComputerName AdldsLds -FeatureName ADLDS -IncludeManagementTools
Copy-LabFileItem -Path "$PSScriptRoot\lds-answers.txt" -DestinationFolderPath 'C:\install' -ComputerName AdldsLds

$vm = Get-LabVM -ComputerName adldslds
$lab = Get-Lab

Invoke-LabCommand -ActivityName "Configure LDS" -ComputerName AdldsLds -ScriptBlock {
	param ($Cred)
	$content = [System.IO.File]::ReadAllText('C:\install\lds-answers.txt')
	$newContent = $content -replace '%PASSWORD%', $Cred.GetNetworkCredential().Password
	$encoding = [System.Text.UTF8Encoding]::new($false)
	[System.IO.File]::WriteAllText('C:\install\lds-answers.txt', $newContent, $encoding)

	& C:\Windows\ADAM\adaminstall.exe /answer:C:\install\lds-answers.txt
} -ArgumentList $vm.GetCredential($lab)
#endregion Install ADLDS

#region Deploy PowerShell Modules
$tempDirectory = New-Item -Path $env:TEMP -Name "PSTemp-$(Get-Random)" -ItemType Directory
Save-Module -Name PSFramework -Path $tempDirectory
Save-Module -Name ADSec -Path $tempDirectory
foreach ($item in Get-ChildItem -Path $tempDirectory) {
	Copy-LabFileItem -Path $item.FullName -DestinationFolderPath "C:\Program Files\WindowsPowerShell\Modules" -ComputerName AdldsAdminHost -Recurse
}
Remove-Item -Path $tempDirectory -Force -Recurse

Copy-LabFileItem -Path "$PSScriptRoot\..\ADLDSMF" -DestinationFolderPath "C:\Program Files\WindowsPowerShell\Modules" -ComputerName AdldsAdminHost -Recurse
#endregion Deploy PowerShell Modules

#region Deploy Example Configuration
foreach ($example in Get-ChildItem -Path "$PSScriptRoot\..\examples") {
	Copy-LabFileItem -Path $example.FullName -DestinationFolderPath 'C:\LdsConfig' -ComputerName AdldsAdminHost -Recurse
}
#endregion Deploy Example Configuration

Restart-LabVM -ComputerName (Get-LabVM).Name