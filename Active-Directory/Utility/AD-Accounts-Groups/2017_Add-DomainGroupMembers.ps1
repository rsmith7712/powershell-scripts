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
    2017_Add-DomainGroupMembers.ps1

.DESCRIPTION
    Adds all enabled store (*STR) user accounts to a specified Active Directory group.

.FUNCTIONALITY
    Bulk-adds store accounts to an AD group.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Function Add-DomainGroupMember($adGroup)
{
    Try
    {
        $strObjs = Get-ADUser -filter "samAccountName -like '*STR'" | Where-Object{$_.Enabled -eq $true}
        $strObjs | 
        ForEach-Object{
            $strObj = $_
            Add-ADGroupMember -Identity $($adGroup) -Members $($strObj.samAccountName) -PassThru
        }
    }
        Catch
        {
            Write-Host "The following exception occurred: $($_.Exception.Message)." -ForegroundColor Yellow
        }
}#===============================[End Function]#===============================
$domainGroup = Read-Host "Enter the group samAccountName to populate"
Add-DomainGroupMember -adGroup $domainGroup