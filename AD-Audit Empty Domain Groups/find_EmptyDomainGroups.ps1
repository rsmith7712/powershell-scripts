<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.129
	 Created on:   	9/9/2016 10:54 AM
	 Created by:   	Richard Smith
	 Organization: 	
	 Filename:     	find_EmptyDomainGroups.ps1
	===========================================================================
	.DESCRIPTION
		Search AD and report all empty domain groups
#>

Import-Module Activedirectory;

Get-ADGroup -filter * -Properties members, DistinguishedName | where {-Not $_.members} | Select Name, DistinguishedName |

Export-Csv -NoTypeInformation C:\report_EmptyDomainGroups.csv;