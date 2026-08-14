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
    domaingradefix.ps1

.DESCRIPTION
    Copies and runs the DomainGrade user-config delete fix on a prompted remote computer via PsExec.

.FUNCTIONALITY
    Applies the DomainGrade config fix to a remote computer.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$computers = Read-Host "Enter Computer Name"

copy-item \\SERVER\SHARE\...\Domaingrade_user.config_delete.bat \\$computers\C$\...\Domaingrade_user.config_delete.bat

copy-item \\SERVER\SHARE\...\Domaingrade_user.config_delete.ps1 \\$computers\C$\...\Domaingrade_user.config_delete.ps1

psexec \\$computers C:\temp\Domaingrade_user.config_delete.bat