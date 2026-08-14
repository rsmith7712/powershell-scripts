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
    goldrawcode.ps1

.DESCRIPTION
    Adds a test alias email address to a remote mailbox via the Exchange snap-in (scratch/reference snippet).

.FUNCTIONALITY
    Adds an alias address to a remote mailbox.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

[string]$aliass = "istemp2"
[string]$NewAliass = "$($aliass)test@example.com"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn;

#Enable-RemoteMailbox -Identity "$aliass" -RemoteRoutingAddress ($aliass + "@domain.mail.onmicrosoft.com")

Set-RemoteMailbox "$aliass" -EmailAddresses @{add="$NewAliass"}