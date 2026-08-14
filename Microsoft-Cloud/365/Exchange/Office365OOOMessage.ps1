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
    Office365OOOMessage.ps1

.DESCRIPTION
    Connects to Exchange Online and sets an internal and external out-of-office auto-reply message for a specified user.

.FUNCTIONALITY
    Sets an Office 365 out-of-office auto-reply.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Write-Host 'Connecting to Office 365 PowerShell' -ForegroundColor Yellow
$O365Cred = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $O365cred -Authentication Basic -AllowRedirection
Write-Host 'Connection to Office 365 Successful' -ForegroundColor Yellow
Write-Host 'Importing Office 365 PSSession' -ForegroundColor Yellow
Import-PSSession $Session -DisableNameChecking |Out-Null
Write-Host 'PSSession Importing has been Completed' -ForegroundColor Green

$user = Read-Host "UserName"
$sdate = Read-Host "Example of Date "7/10/2015 08:00:00" "
$edate = Read-Host "Example of Date "7/10/2015 08:00:00" " 
$msg = Read-Host "Type Internal and External Auto-Reply Message."
Set-MailboxAutoReplyConfiguration -Identity $user -AutoReplyState Enabled -InternalMessage $msg -ExternalMessage $msg


#Set-MailboxAutoReplyConfiguration -Identity tony -AutoReplyState Scheduled -StartTime "7/10/2015 08:00:00" -EndTime "7/15/2015 17:00:00" -#InternalMessage "Internal auto-reply message"