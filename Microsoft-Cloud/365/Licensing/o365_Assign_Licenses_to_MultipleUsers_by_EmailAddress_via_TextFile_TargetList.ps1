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
    o365_Assign_Licenses_to_MultipleUsers_by_EmailAddress_via_TextFile_TargetList_v2.ps1

.DESCRIPTION

         Initial Base:  Microsoft Office 365 Team, Vinayak Latthe (MSDN Blog)
    	 Website: 		https://portal.office.com
    					https://blogs.msdn.microsoft.com/vilath/2015/05/28/bulk-assign-office-365-licenses-to-users/

    	.PURPOSE
            Bulk assign Office 365 Licenses to DirSync users with a script you can run
    			against a Text file containing email address list

        .PREREQUISITES
            1. Go to your C:\ and create a folder called Scripts

    		2.	Copy your user Email list to a text text file and put the users
                email addresses under it one line per user like the example below:

                    janedoe@example.com
                    johndoe@example.com

    			Save the file to C:\Scripts

        .INSTRUCTIONS
            1. Set-ExecutionPolicy RemoteSigned
            2. Hit "Y" when prompted
            3. Run the script â€“ .\licenses.ps1
            4. First prompt is for your Office 365 admin credentials.
            5. Second Prompt is for the location of the UserPrincipalName CSV file,
                just browse to where you saved it (c:\scripts) and select it then hit ok.
            6. Third window will look up the sku of the licenses you purchased.
                Copy and paste the name into the next window and hit ok.
            7. Then the script will run and assign the licenses to the users.

            1. Function (Check-MSOnline) installs the following if not detected:
                --> Install Microsoft Online Services Sign-In Assistant
                http://www.microsoft.com/en-in/download/details.aspx?id=28177

                --> Install Azure AD Module
                https://msdn.microsoft.com/en-us/library/azure/jj151815.aspx

            2.



.FUNCTIONALITY

         Initial Base:  Microsoft Office 365 Team, Vinayak Latthe (MSDN Blog)
    	 Website: 		https://portal.office.com
    					https://blogs.msdn.microsoft.com/vilath/2015/05/28/bulk-assign-office-365-licenses-to-users/

    	.PURPOSE
            Bulk assign Office 365 Licenses to DirSync users with a script you can run
    			against a Text file containing email address list

        .PREREQUISITES
            1. Go to your C:\ and create a folder called Scripts

    		2.	Copy your user Email list to a text text file and put the users
                email addresses under it one line per user like the example below:

                    janedoe@example.com
                    johndoe@example.com

    			Save the file to C:\Scripts

        .INSTRUCTIONS
            1. Set-ExecutionPolicy RemoteSigned
            2. Hit "Y" when prompted
            3. Run the script â€“ .\licenses.ps1
            4. First prompt is for your Office 365 admin credentials.
            5. Second Prompt is for the location of the UserPrincipalName CSV file,
                just browse to where you saved it (c:\scripts) and select it then hit ok.
            6. Third window will look up the sku of the licenses you purchased.
                Copy and paste the name into the next window and hit ok.
            7. Then the script will run and assign the licenses to the users.

            1. Function (Check-MSOnline) installs the following if not detected:
                --> Install Microsoft Online Services Sign-In Assistant
                http://www.microsoft.com/en-in/download/details.aspx?id=28177

                --> Install Azure AD Module
                https://msdn.microsoft.com/en-us/library/azure/jj151815.aspx

            2.



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

# File Pickup Module - Grabs Text file containing Email addresses of users to be licensed
FUNCTION Get-FileName($initialDirectory)
{
	Write-Host "-->using function Get-FileName"
	[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
	$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
	$OpenFileDialog.initialDirectory = $initialDirectory
	$OpenFileDialog.filter = "All files (*.*)| *.*"
	$OpenFileDialog.ShowDialog() | Out-Null
	$OpenFileDialog.filename
}

# Variable that holds text file location - from file pickup module
Write-Host "-->request text file location and store in path variable"
$path = Get-FileName -initialDirectory "c:\"

# Command will list available licenses, SKU codes, and quantity remaining for assignment.
#Write-Host "-->display license information"
#(Get-MsolAccountSku).AccountSkuID
#Get-MsolAccountSku 

# Input window where you provide the license package's name
#Write-Host "-->request SKU and store in server variable"
#$server = read-host 'Provide licensename (AccountSkuId)'

# Array created that includes the plans we want to DISABLE.
$license = @()
#$license += "FLOW_O365_P2" 			# Flow for Office 365
#$license += "POWERAPPS_O365_P2" 		# PowerApps for Office 365
$license += "TEAMS1" 					# Teams 
#$license += "PLANNERSTANDALONE" 		# Planner

#$license += "SWAY" 					# Sway
#$license += "INTUNE_O365" 				# Mobile Device Management for Office 365 
#$license += "YAMMER_ENTERPRISE" 		# Yammer 
#$license += "RMS_S_ENTERPRISE" 		# Azure Rights Management (RMS) 
#$license += "OFFICESUBSCRIPTION" 		# Office Professional Plus 
#$license += "MCOSTANDARD" 				# Skype for Business Online
#$license += "SHAREPOINTWAC" 			# Office Online (Word Online, Excel Online, PowerPoint Online, and OneNote Online)
#$license += "SHAREPOINTENTERPRISE" 	# SharePoint Online
#$license += "EXCHANGE_S_ENTERPRISE" 	# Exchange Online Plan 2


# Create a variable for the license options
$licenseoptions = New-MsolLicenseOptions -AccountSkuId "domain:ENTERPRISEPACK" -DisabledPlans $license

# File import and mailbox assignment loop
Write-Host "-->executing ForEach loop against text file"
$EmailAddress = Get-Content $path
$failures = @()

foreach ($Email in $EmailAddress)
{
	write-host $Email
	$check = (Get-MsolUser -UserPrincipalName $Email).licenses.AccountSkuID
	if ($check -EQ "domain:ENTERPRISEPACK")
	{
		# Set Location
		Set-MsolUser -UserPrincipalName $Email -usagelocation "US"
		
		# Remove E3 License Pack 
		Set-MsolUserLicense -UserPrincipalName $Email -RemoveLicenses "domain:ENTERPRISEPACK"
		
		# Assign E3 License Pack with Disabled Switch $LicenseOptions
		Set-MsolUserLicense -UserPrincipalName $Email -AddLicenses "domain:ENTERPRISEPACK" -LicenseOptions $licenseoptions
		
		# License application check 
		$Check = (Get-MsolUser -UserPrincipalName $Email).licenses.AccountSkuID
		If ($Check -NE "domain:ENTERPRISEPACK")
		{
			write-host "Failed" -ForegroundColor Red
			$failures += $Email
			Append-Log "$Email, Failed"
		}
		else
		{
			write-host "Success" -ForegroundColor Green
			Append-Log "$Email, License Added"
		}
	}
	else
	{
		# E3 License Assignment for New, Previously Unlicensed Users
		Set-MsolUserLicense -UserPrincipalName $Email -AddLicenses "domain:ENTERPRISEPACK" -LicenseOptions $licenseoptions
		
		$Check = (Get-MsolUser -UserPrincipalName $Email).licenses.AccountSkuID
		If ($Check -NE "domain:ENTERPRISEPACK")
		{
			write-host "Failed" -ForegroundColor Red
			$failures += $Email
			Append-Log "$Email, Failed"
		}
		else
		{
			write-host "Success" -ForegroundColor Green
			Append-Log "$Email, License Added"
		}
	}
}

write-host "There were $($failures.count) failures"
Invoke-Item $Global:Logfile


<#
if($failures.count -gt 0)
{
    $failures | Out-File -FilePath C:\o365_userLicenseAssignmentFailures_$DateString.txt
}

#write "-->display post-assignment results"
# Result report on licenses assigned to imported users
#Get-MSOLUser -UserPrincipalName $EmailAddress | out-gridview 

# List unlicensed users in COUNTRY for validation before making licensing changes. 
#Get-MsolUser -All -UnlicensedUsersOnly | Where-Object { $_.Country -eq 'United States' } | Export-Csv "\\SERVER\SHARE\...\log_o365Unlicensed_Users.csv"
#write "us"

# This command will BULK assign the EnterprisePack license to ALL unlicensed users, 
# with a usage location of 'US', in the Domain domain. 
#Get-MsolUser -All -UnlicensedUsersOnly -UsageLocation 'US' | Set-MsolUserLicense -AddLicenses "domain:ENTERPRISEPACK"

#>