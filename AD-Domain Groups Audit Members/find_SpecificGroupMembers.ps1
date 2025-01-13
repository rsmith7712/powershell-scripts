<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.129
	 Created on:   	8/9/2016 10:54 AM
	 Created by:   	Richard Smith
	 Organization: 	
	 Filename:     	find_SpecificGroupMembers.ps1
	===========================================================================
	.DESCRIPTION
		Search AD and report all members of a specific group
#>

Import-Module Activedirectory;

Get-ADGroupMember "Domain Admins" |

Export-Csv -NoTypeInformation C:\report_SpecificGroupMembers.csv;