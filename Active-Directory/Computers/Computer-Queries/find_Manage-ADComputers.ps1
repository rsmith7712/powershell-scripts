# LEGAL
<# LICENSE
    MIT License, Copyright 2022 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
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
    find_Manage-ADComputers.ps1

.DESCRIPTION
    Finds Active Directory computer accounts that have not logged on within a configurable number of days (default 90) for review or cleanup.

.FUNCTIONALITY
    Finds inactive AD computer accounts.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Import-Module ActiveDirectory

# Set the number of days since last logon
$DaysInactive = 90
$InactiveDate = (Get-Date).Adddays(-($DaysInactive))

#-------------------------------
# FIND INACTIVE COMPUTERS
#-------------------------------
# Below are three options to find inactive computers. Select the one that is most appropriate for your requirements:

# Get AD Computers that haven't logged on in xx days
$Computers = Get-ADComputer -Filter { LastLogonDate -lt $InactiveDate -and Enabled -eq $true } -Properties LastLogonDate | Select-Object Name, LastLogonDate, DistinguishedName

# Get AD Computers that have never logged on
$Computers = Get-ADComputer -Filter { LastLogonDate -notlike "*" -and Enabled -eq $true } -Properties LastLogonDate | Select-Object Name, LastLogonDate, DistinguishedName

# Automated way (includes never logged on computers)
$Computers = Search-ADAccount -AccountInactive -DateTime $InactiveDate -ComputersOnly | Select-Object Name, LastLogonDate, Enabled, DistinguishedName

#-------------------------------
# REPORTING
#-------------------------------
# Export results to CSV
$Computers | Export-Csv C:\Temp\InactiveComputers.csv -NoTypeInformation

#-------------------------------
# INACTIVE COMPUTER MANAGEMENT
#-------------------------------
# Below are two options to manage the inactive computers that have been found. Either disable them, or delete them. Select the option that is most appropriate for your requirements:

# Disable Inactive Computers
ForEach ($Item in $Computers){
  $DistName = $Item.DistinguishedName
  Set-ADComputer -Identity $DistName -Enabled $false
  Get-ADComputer -Filter { DistinguishedName -eq $DistName } | Select-Object Name, Enabled
}

# Delete Inactive Computers
ForEach ($Item in $Computers){
  Remove-ADComputer -Identity $Item.DistinguishedName -Confirm:$false
  Write-Output "$($Item.Name) - Deleted"
}