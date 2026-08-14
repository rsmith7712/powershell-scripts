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
    query_AD_LDP_DeletedItems_OutFile_to_Text_2.ps1

.DESCRIPTION
    Queries the Active Directory Deleted Objects container for items whose last-known parent was a specific OU and writes them to a text file (variant).

.FUNCTIONALITY
    Exports AD deleted (tombstoned) objects to text.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>



Get-ADObject -SearchBase "CN=Deleted Objects,DC=DOMAIN,DC=com" -Filter {lastKnownParent -eq "OU=_svcAccts_Users,OU=Disabled Accounts,OU=Domain Services,DC=DOMAIN,DC=com"} -IncludeDeletedObjects | out-file "C:\deletedItems.txt"