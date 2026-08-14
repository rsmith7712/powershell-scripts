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
    Export-List-of-Domain-Controllers-in-Domain.ps1

.DESCRIPTION
    Lists all domain controllers in the Active Directory domain.

.FUNCTIONALITY
    Lists domain controllers.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#List the Domain Controllers of an AD Domain

# Check if the ActiveDirectory module is Loaded
Get-Module -Name ActiveDirectory

# Check if the ActiveDirectory module is available
Get-Module -Name ActiveDirectory -ListAvailable

# Import the ActiveDirectory module if it is not loaded
Import-Module -Name ActiveDirectory

#List all Domain Controllers in the Domain
#Get-ADDomainController

#Display the result in a grid view window
#Get-ADDomainController| out-GridView

#Display the total number of Domain Controllers currently exist in environment.
#Get-ADDomainController | Measure-Object

#Export the List to a CSV File
#Get-ADDomainController | Export-Csv -Path "$home\Desktop\AD-DC-List.csv" -NoTypeInformation
Get-ADDomainController | Export-Csv -Path "C:\tmp\AD-DC-List.csv" -NoTypeInformation