function Get-LdsDomain {
	<#
	.SYNOPSIS
		Returns a pseudo-domain object from an LDS instance.
	
	.DESCRIPTION
		Returns a pseudo-domain object from an LDS instance.
		Use to transparently redirect Get-ADDomain calls.
	
	.PARAMETER LdsServer
		LDS Server instance to use.
		Reads from cache if provided.
	
	.PARAMETER LdsPartition
		LDS partition to use.
		Reads from cache if provided.
	
	.EXAMPLE
		PS C:\> Get-LdsDomain
		
		Returns the default domain
	#>
	param (
		[string]
		$LdsServer = $script:_ldsServer,

		[string]
		$LdsPartition = $script:_ldsPartition
	)

	$object = Get-ADObject -LdapFilter '(objectClass=domainDns)' -Server $LdsServer -SearchBase $LdsPartition -Properties *
	Add-Member -InputObject $object -MemberType NoteProperty -Name NetbiosName -Value $object.Name -Force
	Add-Member -InputObject $object -MemberType NoteProperty -Name DnsRoot -Value ($object.DistinguishedName -replace "DC=" -replace ",", ".") -Force
	$groupSid = Get-ADObject -LdapFilter '(&(objectClass=group)(isCriticalSystemObject=TRUE))' -Server $LdsServer -SearchBase $LdsPartition -Properties ObjectSID -ResultSetSize 1 | ForEach-Object ObjectSID
	Add-Member -InputObject $object -MemberType NoteProperty -Name DomainSID -Value (($groupSid.Value -replace '-\d+$') -as [System.Security.Principal.SecurityIdentifier]) -Force
	$object
}