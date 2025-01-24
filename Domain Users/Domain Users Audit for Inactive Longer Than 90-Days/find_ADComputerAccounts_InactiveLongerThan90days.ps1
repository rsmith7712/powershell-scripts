<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.129
	 Created on:   	9/9/2016 10:12 AM
	 Created by:   	RSmith7712
	 Organization: 	
	 Filename:     	find_ADComputerAccounts_InactiveLongerThan90days.ps1 
	===========================================================================
	.DESCRIPTION
		Find AD Computer Accounts Inactive for Longer Than 90-days 
#> 

Import-Module Activedirectory;

Get-ADComputer -Filter "PasswordLastSet -lt '6/1/2016'" -Properties * | Select Name, PasswordLastSet, LastLogonDate |

Export-Csv -NoTypeInformation C:\report_ADComputerAccounts_InactiveLongerThan90days.csv;