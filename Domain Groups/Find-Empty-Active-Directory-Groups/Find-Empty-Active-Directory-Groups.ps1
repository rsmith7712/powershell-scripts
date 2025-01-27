# LEGAL
<# LICENSE
    MIT License, Copyright 2023 Richard Smith

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
.NAME
   - Find-Empty-Active-Directory-Groups.ps1

.SYNOPSIS
   - Code will produce all the empty groups in your
    domain and export it to a csv file.

.FUNCTIONALITY
   - URL #1 
    https://www.enterprisedaddy.com/2015/02/find-empty-groups-in-active-directory-using-powershell/

    REFERENCE URL: MICROSOFT, Global Catalog and LDAP Searches
    https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-2000-server/cc978012(v=technet.10)?redirectedfrom=MSDN

    URL #2 
    https://www.techcrafters.com/portal/en/kb/articles/cleanup-empty-groups-active-directory-powershell#Cleanup_Empty_AD_Groups_with_PowerShell

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Import-Module ActiveDirectory

#-------------------------------
# FIND EMPTY GROUPS
#-------------------------------

#Scope: ENTIRE DOMAIN; ALL ACTIVE DIRECTORY (INCLUDING BUILTIN)
$Group1 = Get-ADGroup -Filter * -Properties Members | where {-not $_.members} | select Name

#Scope: GET EMPTY ACTIVE DIRECTORY GROUPS WITHIN A SPECIFIC OU
#$Group2 = Get-ADGroup -Filter { Members -notlike "*" } -SearchBase "OU=GROUPS,DC=DOMAIN,DC=com" | Select-Object Name, GroupCategory, DistinguishedName

#Scope: GET MEMBERS OF SPECIFIC ACTIVE DIRECTORY OU
#$Group3 = Get-ADGroup 'Finance Team' | Get-Member#

#Scope: CHECK FOR EMPTY ACTIVE DIRECTORY GROUPS IN ANOTHER DOMAIN; USING PORT 3268
#$Group4 = Get-ADGroup -Filter * -Properties Members –server DomainName:3268 | where {-not $_.members} | select Name

#-------------------------------
# REPORTING
#-------------------------------

# Export results to CSV
$Group1 | Export-Csv "C:\scripts\Empty-Active-Directory-Groups.csv" –NoTypeInformation
#$Group2 | Export-Csv "C:\scripts\Empty-Active-Directory-Group-Specific-OU.csv" –NoTypeInformation
#$Group3 | Export-Csv "C:\scripts\Members-Active-Directory-Group-Specific-OU.csv" –NoTypeInformation
#$Group4 | Export-Csv "C:\scripts\Members-Active-Directory-Group-Specific-Domain.csv" –NoTypeInformation


#-------------------------------
# INACTIVE GROUP MANAGEMENT
#-------------------------------

<#
#Scope: Group1, Delete Inactive Groups
ForEach ($Item in $Group1){
  Remove-ADGroup -Identity $Item.DistinguishedName -Confirm:$false -WhatIf
  Write-Output "$($Item.Name) - Deleted"
  }

  #Scope: Group2, Delete Inactive Groups
ForEach ($Item in $Group2){
  Remove-ADGroup -Identity $Item.DistinguishedName -Confirm:$false -WhatIf
  Write-Output "$($Item.Name) - Deleted"
  }

  #Scope: Group3, Delete Inactive Groups
ForEach ($Item in $Group3){
  Remove-ADGroup -Identity $Item.DistinguishedName -Confirm:$false -WhatIf
  Write-Output "$($Item.Name) - Deleted"
  }

  #Scope: Group4, Delete Inactive Groups
ForEach ($Item in $Group4){
  Remove-ADGroup -Identity $Item.DistinguishedName -Confirm:$false -WhatIf
  Write-Output "$($Item.Name) - Deleted"
  }
  #>