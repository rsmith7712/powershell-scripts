# LEGAL
<# LICENSE
    MIT License, Copyright 2023 Richard Smith

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
    Find-Computer-Objects-Older-Than-365-Days-Export-to-Txt.ps1

.DESCRIPTION
    Exports Active Directory computer accounts that have not changed their password in over 365 days (disabled and orphaned) to text files.

.FUNCTIONALITY
    Reports stale and orphaned AD computer accounts.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#
Computers change their account password every 30 days by default. 
If a computer hasn't changed its password in an extended period 
of time, it means that they are no longer connected to the network.

This script will output 2 text files. One is for 
disabled computers, one is for orphaned computer account objects.
 
You must have the Active Directory PowerShell module installed.

In this example, I exclude an "Encrypted Laptops" OU, since 
they're mobile laptops that are disconnected for extended periods 
of time. You can remove that section if you don't have a similar setup
#>

Import-Module ActiveDirectory

$Date = [DateTime]::Today

#Sets the deadline for when computers should have last changed their password by.
$Deadline = $Date.AddDays(-365)   

#Makes the date string for file naming
$FileName = [string]$Date.month + [string]$Date.day + [string]$Date.year 


#Generates a list of computer accounts that are enabled and aren't in the Encrypted Computers OU, but haven't set their password since $Deadline
$OldList = Get-ADComputer -Filter {(PasswordLastSet -le $Deadline) -and (Enabled -eq $TRUE)} -Properties PasswordLastSet -ResultSetSize $NULL |
Where {$_.DistinguishedName -notlike "*Encrypted Laptops*"} | 
Sort-Object -property Name | FT Name,PasswordLastSet,Enabled -auto 

#Generates a list of computer accounts that are disabled and sorts by name.
$DisabledList = Get-ADComputer -Filter {(Enabled -eq $FALSE)} -Properties PasswordLastSet -ResultSetSize $null | 
Sort-Object -property Name | FT Name,PasswordLastSet,Enabled -auto

#Creates the two files, assuming they are not $NULL. If they are $NULL, the file will not be created.
if ($OldList -ne $NULL) {
    Out-File "C:\temp\Orphaned-Computer-Objects-$Filename.txt" -InputObject $OldList
}

if ($DisabledList -ne $NULL) {
    Out-File "C:\temp\Disabled-Computer-Objects-$Filename.txt" -InputObject $DisabledList
}