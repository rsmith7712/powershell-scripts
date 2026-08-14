# 90 day inactive user report (pulling from Active Directory)
# Base script created by PowerShell Newbie, 2011
# Mod by Pirate 2016-05-20


import-module ActiveDirectory 
Search-ADAccount -UsersOnly -SearchBase "ou=DEFINE,ou=DEFINE,ou=DEFINE,dc=domain,dc=com" -AccountInactive -TimeSpan 90 | 
Get-ADUser -Properties Name, sAMAccountName, givenName, sn, userAccountControl | 
Where {($_.userAccountControl -band 2) -eq $False} | 
Select sAMAccountName, givenName, sn | 
Sort-Object sAMAccountName | 
export-csv c:\90day-Inactive-Users.csv -NoTypeInformation