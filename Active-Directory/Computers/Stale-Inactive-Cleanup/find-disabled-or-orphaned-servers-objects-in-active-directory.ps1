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
    find-disabled-or-orphaned-servers-objects-in-active-directory.ps1

.DESCRIPTION
    Finds Active Directory server computer accounts that are disabled or disabled-and-not-in-production.

.FUNCTIONALITY
    Reports disabled and orphaned AD servers.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# find-disabled-or-orphaned-servers-objects-in-active-directory.ps1

<#
find only servers that have either been disabled, or disabled and not in production
#>


Import-Module ActiveDirectory

$Date = [DateTime]::Today

#Sets the deadline for when computers should have last changed their password by.
$Deadline = $Date.AddDays(-365)   

#Makes the date string for file naming
$FileName = [string]$Date.month + [string]$Date.day + [string]$Date.year 

#Generates a list of computer server accounts that are enabled, but haven't set their password since $Deadline
$OldList = Get-ADComputer -Filter {(PasswordLastSet -le $Deadline) -and (Enabled -eq $TRUE) -and (OperatingSystem -Like "Windows *Server*")} -Properties PasswordLastSet -ResultSetSize $NULL |
Sort-Object -property Name | FT Name,PasswordLastSet,Enabled -auto 

#Generates a list of computer server accounts that are disabled and sorts by name.
$DisabledList = Get-ADComputer -Filter {(Enabled -eq $FALSE) -and (OperatingSystem -Like "Windows *Server*")} -Properties PasswordLastSet -ResultSetSize $null | 
Sort-Object -property Name | FT Name,PasswordLastSet,Enabled -auto

#Creates the two files, assuming they are not $NULL. If they are $NULL, the file will not be created.
if ($OldList -ne $NULL) {
    Out-File "C:\temp\ServersEnabled_PasswordsGreaterThan365Days_$Filename.txt" -InputObject $OldList
}

if ($DisabledList -ne $NULL) {
    Out-File "C:\temp\ServersDisabled_$Filename.txt" -InputObject $DisabledList
} 