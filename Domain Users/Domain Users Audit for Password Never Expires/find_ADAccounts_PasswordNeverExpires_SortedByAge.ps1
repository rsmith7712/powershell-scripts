# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith, Eric Rocconi

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the “Software”),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
#>
# GENERAL SCRIPT INFORMATION
<#
.DESCRIPTION
  find_ADAccounts_PasswordNeverExpires_SortedByAge.ps1

.FUNCTIONALITY
	- Find all AD Accounts whose passwords are set to never expire
	- Sort results by age
	- Export to CSV

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>

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