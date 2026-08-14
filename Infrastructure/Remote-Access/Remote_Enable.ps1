# LEGAL
<# LICENSE
    MIT License, Copyright 2014 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the “Software”),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS
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
    Remote_Enable.ps1

.SYNOPSIS
  Turns on Remote-Powershell but locks it down to the AD group, ORGADMINS.
 
.DESCRIPTION
  Remote Powershell. http://powershell.com/cs/forums/t/8005.aspx
 
.NOTES
  Version:        1.0
  Author:         user26
  Creation Date:  10/24/2014
  Purpose/Change: Initial Script Development.

.HISTORY

.FUNCTIONALITY
    Remote Powershell. http://powershell.com/cs/forums/t/8005.aspx

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$AuthGroups = "O:NSG:BAD:P(A;;GA;;;S-1-5-21-2147253334-2137588867-316619961-25598)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)"

Enable-PSRemoting -force

Set-PSSessionConfiguration Microsoft.Powershell -SecurityDescriptorSDDL $AuthGroups -force