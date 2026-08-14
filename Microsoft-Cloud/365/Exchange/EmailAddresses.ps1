# EmailAddresses.ps1

import-module servermanager
Add-WindowsFeature -Name "RSAT-AD-PowerShell" -IncludeAllSubFeature
Get-ADUser -Filter * -Properties DisplayName, EmailAddress, Title | select DisplayName, EmailAddress, Title | Export-CSV "C:\temp\Email_Addresses.csv"

#Found on Spiceworks: https://community.spiceworks.com/how_to/86794-powershell-how-to-export-displayname-email-address-and-title-from-ad-to-csv-file?utm_source=copy_paste&utm_campaign=growth