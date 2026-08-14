# LEGAL
<# LICENSE
    MIT License, Copyright 2017 Richard Smith

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
    misc-ADUser-Queries_2.ps1

.DESCRIPTION
    A collection of miscellaneous Active Directory user queries (account counts, disabled accounts, etc.) (variant).

.FUNCTIONALITY
    Miscellaneous AD user queries.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#

misc-ADUser-Queries.ps1

#>

# Calculate the total number of user account in the Active Directory:

Get-ADUser -Filter {SamAccountName -like "*"} | Measure-Object

# Find disabled Active Directory user accounts:

Get-ADUser -Filter {Enabled -eq "False"} | Select-Object SamAccountName,Name,Surname,GivenName | Format-Table

# Check Active Directory user account creation date with the command:

Get-ADuser -Filter * -Properties Name, WhenCreated | Select name, whenCreated

# List  accounts with an expired password (you can configure password expiration options in the domain password policy):

Get-ADUser -filter {Enabled -eq $True} -properties name,passwordExpired| where {$_.PasswordExpired}|select name,passwordexpired

# Users who haven’t changed their passwords in the last 90 days:

$90_Days = (Get-Date).adddays(-90)
Get-ADUser -filter {(passwordlastset -le $90_days)}

# Get a list of AD groups which the user account is a member of:

Get-AdUser admin2 -Properties memberof | Select memberof -expandproperty memberof

