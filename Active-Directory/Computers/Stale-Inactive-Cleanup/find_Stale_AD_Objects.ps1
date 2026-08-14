<#

.Name:	   find_Stale_AD_Objects.ps1
.Purpose:  To check AD for stale computer objects based on date logon criteria and disable / delete
.Author:   Paperclips
.Email:	   pwd9000@hotmail.co.uk
.Date:     Oct 2013
.Comments: Can be scheduled to run e.g. weekly to eleviate manual checks
.Notes:

This script can be used to check Active Directory (Computer Objects) for
old and stale computers that has not been logged into for a certain period of time.

If the script detects any computers that has not been logged into on the
domain for the "x" amount of time which is configurable under "line9"
($year-variable) the computer object will be disabled and also moved to
a relevant OU (In the case of this script on line 14 the OU is:
"OU=Disabled Computers,DC=my,DC=domain,DC=local" - This can also
be changed to the DN of the OU in your environment by amending this line.

Additionally "line10" ($1y1m-variable) will then also completely
remove (!delete!) computer objects on "line 17"

** If you do not want to delete any objects but want to still use the
diable/move functions please comment out lines "10" and "17"

Most of the variables are adjustable and can be changed to suit
your environment.
#>

# Variables
#$1year = (Get-Date).AddDays(-365) # The 365 is the number of days from today since the last logon.
#$1y1m = (Get-Date).AddDays(-395)

$1month = (Get-Date).AddDays(-30) # The 30 is the number of days from today since the last logon.
$2m5d = (Get-Date).AddDays(-65)

# Disable computer objects and move to disabled OU (Older than 1 year):
#Get-ADComputer -Property Name,lastLogonDate -Filter {lastLogonDate -lt $1year} | Set-ADComputer -Enabled $false -WhatIf
#Get-ADComputer -Property Name,Enabled -Filter {Enabled -eq $False} | Move-ADObject -TargetPath "OU=Disabled Computers,DC=my,DC=domain,DC=com" -WhatIf

# Delete Older Disabled computer objects:
#Get-ADComputer -Property Name,lastLogonDate -Filter {lastLogonDate -lt $2m5d} | Remove-ADComputer -WhatIf

Get-ADComputer -Property Name,lastLogonDate -Filter {lastLogonDate -lt $2m5d} | Export-Csv -NoTypeInformation C:\Temp\report-find_Stale_AD_Objects.csv