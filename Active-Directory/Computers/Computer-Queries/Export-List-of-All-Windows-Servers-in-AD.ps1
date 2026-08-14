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
    Export-List-of-All-Windows-Servers-in-AD.ps1

.DESCRIPTION
    Exports all Windows Server computer accounts (DNS host name, OS, IPv4) from Active Directory to a CSV.

.FUNCTIONALITY
    Exports Windows servers from AD to CSV.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#Connect to Active Directory
Import-Module ActiveDirectory

#Retrieve server systems from Active Directory
#Get-ADComputer -Filter {OperatingSystem -like "*windows*server*"} -Properties DNSHostName, OperatingSystem,IPv4Address | Sort-Object DNSHostname

#Export the List to a CSV File
Get-ADComputer -Filter {OperatingSystem -like "*windows*server*"} -Properties DNSHostName, OperatingSystem,IPv4Address | Sort-Object DNSHostname | Export-Csv -Path "C:\tmp\ADServers.csv" -NoTypeInformation
