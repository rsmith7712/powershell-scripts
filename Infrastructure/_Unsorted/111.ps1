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
    111.ps1

.DESCRIPTION
    		A description of the file.

.FUNCTIONALITY
    		A description of the file.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Verifies that MSOnline module is installed and runs the installer if not.
FUNCTION Check-MSOnline
{
	$check = (Get-Module -ListAvailable -name msonline).Name
	if ($check -eq "MSOnline")
	{
	}
	else
	{
		if (!(test-path C:\Software))
		{
			New-Item -Path C:\Software -ItemType Directory
			Copy-Item -path "\\SERVER\SHARE\...\msoidcli_64.msi" -Destination C:\Software\msoidcli_64.msi -Force
			Copy-Item -path "\\SERVER\SHARE\...\AdministrationConfig-en.msi" -destination C:\Software\AdministrationConfig-en.msi -Force
			Start-Process msiexec.exe -ArgumentList "/i C:\software\msoidcli_64.msi /qn" -wait
			Start-Process msiexec.exe -ArgumentList "/i C:\software\AdministrationConfig-en.msi /qn" -wait
		}
		else
		{
			Copy-Item -path "\\SERVER\SHARE\...\Desktop Software\Powershell\msonline\msoidcli_64.msi" -Destination C:\Software\msoidcli_64.msi -Force
			Copy-Item -path "\\SERVER\SHARE\...\Desktop Software\Powershell\msonline\AdministrationConfig-en.msi" -destination C:\Software\AdministrationConfig-en.msi -Force
			Start-Process msiexec.exe -ArgumentList "/i C:\Software\msoidcli_64.msi /qn" -wait
			Start-Process msiexec.exe -ArgumentList "/i C:\Software\AdministrationConfig-en.msi /qn" -wait
		}
	}
}

Check-MSOnline

# Import module for Azure Active Directory 
Write-Host "-->module import - MSOnline for Azure AD"
Import-Module MSOnline

# Create DateString variable to append to end of each file generated
$DateString = get-date -Format HHmmss

# Create global variable: Logfile :and point it toward the ErrorLogfile CSV with _$DateString at end
$Global:Logfile = "C:\o365_PostLicensingAssignment_LogFile_$DateString.csv"
New-Item -Path $Global:Logfile -ItemType File -Force
Add-Content $Global:Logfile "UserAccount, Status"

FUNCTION Append-Log($message)
{
	Add-Content $Global:Logfile "$message"
}

# Capture admin credential for authentication
Write-Host "-->credential request"
$credential = Get-Credential

# Establish connection to Azure AD Online Services 
Write-Host "-->connect to MS Online"
Connect-MsolService -Credential $credential

# Command will list available licenses, SKU codes, and quantity remaining for assignment.
Write-Host "-->display license information"
(Get-MsolAccountSku).AccountSkuID