<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.129
	 Created on:   	9/9/2016 10:12 AM
	 Created by:   	RSmith7712
	 Organization: 	
	 Filename:     	find_ADComputerAccounts_InactiveLongerThan90days_andDisable.ps1 
	===========================================================================
	.DESCRIPTION
		Find AD Computer Accounts Inactive for Longer Than 90-days, and disable them
#>

Import-Module Activedirectory;

# Identify and document systems that have not had their password changed since Xdate
Get-ADComputer -Filter "PasswordLastSet -lt '6/1/2016'" -Properties * | Select Name, PasswordLastSet, LastLogonDate | 

# Export identified systems to CSV 
Export-Csv -NoTypeInformation C:\report_ADComputerAccounts_InactiveLongerThan90days_NOW_Disable.csv; 

# Same query but this time to disable previously identified systems
Get-ADComputer -Filter "PasswordLastSet -lt '6/1/2016'" -Properties * | Disable-ADAccount -WhatIf