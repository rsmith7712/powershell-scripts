Import-Module ActiveDirectory

#Cleanup empty AD Groups
#https://gist.github.com/9to5IT/be02956ca8f388e9150a5af097304b74

#-------------------------------
# FIND EMPTY GROUPS
#-------------------------------

# Get empty AD Groups within a specific OU
$Groups = Get-ADGroup -Filter { Members -notlike "*" } -SearchBase "DC=Domain,DC=com" | Select-Object Name, GroupCategory, DistinguishedName

#-------------------------------
# REPORTING
#-------------------------------

# Export results to CSV
$Groups | Export-Csv C:\Temp\InactiveGroups.csv -NoTypeInformation

#-------------------------------
# INACTIVE GROUP MANAGEMENT
#-------------------------------

# Delete Inactive Groups
ForEach ($Item in $Groups){
  Remove-ADGroup -Identity $Item.DistinguishedName -Confirm:$false -WhatIf
  Write-Output "$($Item.Name) - Deleted"
}