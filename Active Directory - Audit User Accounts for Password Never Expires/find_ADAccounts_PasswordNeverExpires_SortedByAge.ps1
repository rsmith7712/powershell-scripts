<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.129
	 Created on:   	9/12/2016 9:51 AM
	 Created by:   	RSmith7712, Rocconi
	 Organization: 	
	 Filename:     	find_ADAccounts_PasswordNeverExpires_SortedByAge.ps1
	===========================================================================
	.DESCRIPTION
		- Find all AD Accounts whose passwords are set to never expire
        - Sort results by age
        - Export to CSV
#>
# 

Import-Module Activedirectory;

### Password Age Report - Exported to HTML ###
Get-ADUser -Filter "Enabled -eq 'True' -AND PasswordNeverExpires -eq 'True'" -Properties PasswordLastSet,PasswordNeverExpires,PasswordExpired |

Select Name, pass*, @{ Name = "PasswordAge"; Expression = { (Get-Date) - $_.PasswordLastSet } }, DistinguishedName | sort PasswordAge -Descending | ConvertTo-Html -Title "Password Age Report Sorted By AGE" |

Out-File c:\report_ADAccounts_PasswordNeverExpires_SortedByAge.htm

### Password Age Report - Exported to CSV ###
#-1-Get-ADUser -Filter "Enabled -eq 'True' -AND PasswordNeverExpires -eq 'True'" -Properties LastLogonDate,PasswordLastSet,PasswordNeverExpires,PasswordExpired |

#-2-Select Name, LastLogonDate, pass*, @{ Name = "PasswordAge"; Expression = { (Get-Date) - $_.PasswordLastSet } }, DistinguishedName | sort PasswordAge -Descending |

#-3-Export-Csv -NoTypeInformation C:\report_ADAccounts_PasswordNeverExpire_SortedByAge.csv;

#*****************************************************************
# Sets the Exclusion OU's
$ExclusionOUs = @("Register, Service Accounts, OU=Domain Services, DC=DOMAIN, DC=com")
	
	Get-ADUser -Filter "Enabled -eq 'True' -AND PasswordNeverExpires -eq 'True'" -Properties LastLogonDate, PasswordLastSet, PasswordNeverExpires, PasswordExpired | ?{ ($_.DistinguishedName -notmatch $ExclusionOUs) } |
		Select Name, LastLogonDate, pass*, @{ Name = "PasswordAge"; Expression = { (Get-Date) - $_.PasswordLastSet } }, DistinguishedName |
		Sort PasswordAge -Descending |
	
	Export-Csv -NoTypeInformation C:\report_ADAccounts_PasswordNeverExpire_SortedByAge.csv