# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith

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
    o365-standard.ps1

.DESCRIPTION
    		Applies standard licensing to o365 user

.FUNCTIONALITY
    		Applies standard licensing to o365 user

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#verifies that msonline module is installed and installs it if it is not.

function check-mso
{
	if (Get-Module -ListAvailable -Name mso*)
	{
	}
	else
	{
		Copy-Item -path "\\SERVER\SHARE\...\Desktop Software\Powershell\msonline\msoidcli_64.msi" -Destination C:\Software\msoidcli_64.msi
		Copy-Item -path "\\SERVER\SHARE\...\Desktop Software\Powershell\msonline\AdministrationConfig-en.msi" -destination C:\Software\Administrationconfig-en.msi
		msiexec /a C:\Software\msoidcli_64.msi /qn
		msiexec /a C:\Software\AdministrationConfig-en.msi /qn
	}
}

check-mso

$user = Read-Host "enter user name"
$username = $user + "@example.com"

Import-Module msonline
Import-Module msonlineextended
Connect-msolservice

set-msoluserlicense -userprincipalname $username -addlicenses #put license options here