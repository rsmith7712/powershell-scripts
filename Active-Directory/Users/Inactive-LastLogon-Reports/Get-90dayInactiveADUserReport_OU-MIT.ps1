# 90 day inactive user report (pulling from Active Directory)
# Created by PowerShell Newbie, 2011
# Mod by Pirate 2016-05-20


import-module activedirectory 
Search-ADAccount -UsersOnly -SearchBase "ou=MIT,ou=Service Accounts,ou=Domain Services,dc=Domain,dc=com" -AccountInactive -TimeSpan 90 | 
Get-ADUser -Properties Name, sAMAccountName, givenName, sn, userAccountControl | 
Where {($_.userAccountControl -band 2) -eq $False} | 
Select sAMAccountName, givenName, sn | 
Sort-Object sAMAccountName | 
export-csv c:\90day_Inactive_Users_OU-MIT.csv -NoTypeInformation