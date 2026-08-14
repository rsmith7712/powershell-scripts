# LEGAL
<# LICENSE
    MIT License, Copyright 2017 Richard Smith

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
    Revoke_license_list.ps1

.DESCRIPTION
    		Takes a list of users and revokes the O365 E3 license if it is found.

.FUNCTIONALITY
    		Takes a list of users and revokes the O365 E3 license if it is found.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

function check-msonline
{
	$check = (Get-Module -ListAvailable -name msonline).Name
	if ($check -eq "MSOnline")
	{
	}
	else
	{
		if (!(test-path C:\software))
		{
			New-Item -Path C:\Software -ItemType Directory
			Copy-Item -path "\\SERVER\SHARE\...\Desktop Software\Powershell\msonline\msoidcli_64.msi" -Destination C:\Software\msoidcli_64.msi -Force
			Copy-Item -path "\\SERVER\SHARE\...\Desktop Software\Powershell\msonline\AdministrationConfig-en.msi" -destination C:\Software\Administrationconfig-en.msi -Force
			Start-Process msiexec.exe -ArgumentList "/i C:\software\msoidcli_64.msi /qn" -wait
			Start-Process msiexec.exe -ArgumentList "/i C:\software\Administrationconfig-en.msi /qn" -wait
		}
		else
		{
			Copy-Item -path "\\SERVER\SHARE\...\Desktop Software\Powershell\msonline\msoidcli_64.msi" -Destination C:\Software\msoidcli_64.msi -Force
			Copy-Item -path "\\SERVER\SHARE\...\Desktop Software\Powershell\msonline\AdministrationConfig-en.msi" -destination C:\Software\Administrationconfig-en.msi -Force
			Start-Process msiexec.exe -ArgumentList "/i C:\software\msoidcli_64.msi /qn" -wait
			Start-Process msiexec.exe -ArgumentList "/i C:\software\Administrationconfig-en.msi /qn" -wait
		}
	}
}

#verifies that the necessary powershell modules are installed
check-msonline

#Prompts for O365 admin creds
Connect-MsolService

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = Get-Date -Format "HHmmss"
$Script:Logfile = "C:\Revoked_Licenses_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "Username, Status"
function Append-Log($message)
{
	Add-Content $Script:LogFile "$message"
}
# ----------------------------------------------------------------------------------------------

#The list of users that will have licenses revoked
$users = Get-Content "C:\temp\users.txt"

#Checks for an existing license and revokes it if it is found
foreach($user in $users)
{
    $check = (Get-MsolUser -UserPrincipalName $user).licenses.accountskuid
    if($check -eq "domain:ENTERPRISEPACK")
    {
        Set-MsolUserLicense -UserPrincipalName $user -RemoveLicenses domain:ENTERPRISEPACK
        Append-Log "$user, License Revoked"
    }
    else
    {
        Append-Log "$user, No Existing License"
    }
}