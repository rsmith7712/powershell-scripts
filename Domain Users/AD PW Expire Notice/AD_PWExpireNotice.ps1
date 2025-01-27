# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Damien Gibson

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
   - AD_PWExpireNotice.ps1

.SYNOPSIS
    - The purpose of this script is to find all users in AD that have 5 days
	until AD PW Expiration, and send them a reminder email.

.FUNCTIONALITY
    - This Tool will scan AD and query a list of accounts that have 5 days until
	the users AD PW Expires. The tool then emails each person on this list a
	detailed message explaining that their PW will expire and how to go about
	changing the password, by different connection methods.

	Requirements: Active Directory Module - **which is installed with RSAT.

	Create a scheduled task to run it daily at the time you wish.
	
	The action of the scheduled task should have the "Program/script" field as
	the path to PowerShell on that server.
	eg: %SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe
	
	The arguments line should have "-ExecutionPolicy Bypass " and then the
	path to this script.
	eg: -ExecutionPolicy Bypass C:\Scripts\Email-PasswordExpiry.ps1

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

################################
#     Editable Variables       #
################################

# Email account to send the email from
$From = "Helpdesk@DOMAIN.com"

# Mail server to send the email from
$SMTPServer = "SSC.DOMAIN.com"

# Subject of the email
$MailSubject = "Important Reminder: Your password will expire soon."

# Number of days before password expires to start sending the emails
$DaysBeforeExpiry = "5"

# Do you wish to setup this script for testing? (Yes/No)
$SetupForTesting = "No"
# What username do you wish to test with?
$TestingUsername = "redOctober"


#################################
# Do not modify below this line #
#################################

### Attempts to Import ActiveDirectory Module. Produces error if fails.
Try { Import-Module ActiveDirectory -ErrorAction Stop}
Catch { Write-Host "Unable to load Active Directory module, is RSAT installed?"; Break}

### Set the maximum password age based on group policy if not supplied in parameters.
if ($maxPasswordAge -eq $null){
	$maxPasswordAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge
}
if ($SetupForTesting -eq "Yes"){
	$CommandToGetInfoFromAD = Get-ADUser -Identity $TestingUsername -properties PasswordLastSet, PasswordExpired, PasswordNeverExpires, EmailAddress, GivenName
	Clear-Variable DaysBeforeExpiry
	$DaysBeforeExpiry = "1000"
}
else{
	$CommandToGetInfoFromAD = Get-ADUser -filter * -properties PasswordLastSet, PasswordExpired, PasswordNeverExpires, EmailAddress, GivenName
}

#Run the command to get information from Active Directory
$CommandToGetInfoFromAD | ForEach {
	$Today = (Get-Date)
	$UserName = $_.GivenName
	if (!$_.PasswordExpired -and !$_.PasswordNeverExpires){
		$ExpiryDate = ($_.PasswordLastSet + $maxPasswordAge)
		$ExpiryDateForEmail = $ExpiryDate.ToString("dddd, MMMM dd yyyy a\t hh:mm tt")
		$DaysLeft = ($ExpiryDate - $Today).days
		if ($DaysLeft -lt $DaysBeforeExpiry -and $DaysLeft -gt 0){
			$MailProperties = @{
				From = $From
				To = $_.EmailAddress
				Subject = $MailSubject
				SMTPServer = $SMTPServer
			}
			### Message Body for email
			$MsgBody = @"
<p>$UserName,</p>
<p>Your Windows password expires on $ExpiryDateForEmail. You have $DaysLeft days left before your password expires. 
Please change your password <span style="font-weight: bold; color: red;">before</span> it expires to prevent
an interruption of access (saversnet, email, computers, etc).</p>
<p><span style="font-weight: bold; font-size: 1.2em;">Users in the Office:</span><br>
Please change your Windows password by pressing CTRL+ALT+DEL and selecting "Change a Password".</p>
<p><span style="font-weight: bold; font-size: 1.2em;">Users on VPN?:</span><br>
For those people who are out of the office and or remote users, please make sure you are connected to the VPN when you try to change 
your password, or you won't be able to change it. Once your password is changed please then Lock your computer (CTRL+ALT+DEL &gt; Lock this 
computer), and unlock it with your new password. This will force Windows to check with the domain and 
pull down your latest password to ensure you have access to all normal resources.</p>
<p><span style="font-weight: bold; font-size: 1.2em;">Do you have a Mobile Phone with your email on it?:</span><br>
After you change your password, if you have a mobile phone with your email on it, you will need to update the 
password on your phone to continue to receive emails. If you do not update this, it may cause you to be locked out.</p>
<br>
<p>Service Desk<br>
000-0000-0000<br>
<a href="mailto:helpdesk@symetrix.co">E-Mail the Service Desk</a></p>
"@
			
			### Sends email to user with the message in $MsgBody variable and the supplied @MailProperties.
			Send-MailMessage @MailProperties -body $MsgBody -BodyAsHtml
		}
	}
}