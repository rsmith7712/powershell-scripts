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
    mass-mailboxmigration.ps1

.DESCRIPTION
    Ensures the MSOnline module is installed, then performs a bulk mailbox migration to Office 365.

.FUNCTIONALITY
    Bulk-migrates mailboxes to Office 365.

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

check-msonline

$cred = Get-Credential

$users = Get-Content "C:\temp\users.txt"

Connect-MsolService -Credential $cred

$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $cred -Authentication basic -AllowRedirection

Import-PSSession $session

foreach($user in $users)
{
    New-MoveRequest -Identity $user -Remote -RemoteHostName webmail.example.com -TargetDeliveryDomain domain.mail.onmicrosoft.com -RemoteCredential $cred -BadItemLimit 50
}

Write-Host "----> Select Option"
Write-Host "1. View Progress"
Write-Host "q. Quit"

do
{
    $switch = Read-Host "Enter selection"
    switch ($switch)
    {
        '1'
        {
            get-moverequest | get-moverequeststatistics -includereport
        }
        'q'
        {
            break
        }
    }
}
until ($switch -eq 'q')
