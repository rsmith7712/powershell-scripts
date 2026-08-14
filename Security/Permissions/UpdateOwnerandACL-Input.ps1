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
    UpdateOwnerandACL-Input.ps1

.DESCRIPTION
    Prompts for a path and updates its owner and ACL using the Set-Owner function.

.FUNCTIONALITY
    Updates file/folder owner and ACL.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#Import Powershell AD Module

Import-Module ActiveDirectory

#Load Set-Owner function

. E:\Powershell\Functions\Set-Owner.ps1


#Get user input for file permsssion update

$path = Read-Host "Enter the full path you wish to update"
$ACLFile = Read-Host "Enter the full path of the reference folder to propagate permissions from"

Get-ChildItem $path -recurse -Force |% {


    # Change Owner

            Set-Owner -Path $_.fullname -Verbose -Account "DOMAIN_2000\Domain Admins"
            Set Acl
            Get-Acl $ACLfile | Set-Acl -Path $_.fullname

    # Update permissions based on reference file and allow inheritance

            $acl = Get-Acl $ACLfile
            $acl.SetAccessRuleProtection($false,$true)
            Set-Acl -Path $_.fullname $acl -Verbose
    
  
}