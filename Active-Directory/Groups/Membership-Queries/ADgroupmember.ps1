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
    ADgroupmember.ps1

.DESCRIPTION
    Builds a list of enabled users from several OUs and compares it against the membership of a company distribution group.

.FUNCTIONALITY
    Compares OU user lists against a group's membership.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Import-Module ActiveDirectory

$userlist = get-aduser -SearchBase "ou=corporate accounts,dc=domain,dc=com" -Filter {Enabled -eq "True"} | Select samaccountname
$userlist += get-aduser -SearchBase "ou=External Accounts,ou=domain services,dc=domain,dc=com" -Filter {Enabled -eq "True"} | Select samaccountname
$userlist += get-aduser -SearchBase "ou=Remote Accounts,dc=domain,dc=com" -Filter {Enabled -eq "True"} | Select samaccountname

$grouplist = get-adgroupmember -Identity "cn=*all company employees,ou=Corporate DL,ou=Distribution,ou=Group Accounts,dc=domain,dc=com" | select samaccountname

#$userlist | ?{$grouplist -notcontains $_}

$output = @()

foreach($user in $userlist)
{
    If(!($grouplist.Contains($User))){
        $output += $user
        }
}
