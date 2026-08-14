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
    Set-OOO.ps1

.DESCRIPTION
    Interactively prompts for a mailbox and date range and sets a scheduled out-of-office auto-reply, then displays the result.

.FUNCTIONALITY
    Sets a scheduled out-of-office reply interactively.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Write-host -ForegroundColor Magenta "Please keep the AU's E-Mail address, Start time, End Time, Internal OOO message & External OOO Message ready with you now ... If not then press CTRL + C to stop the script execution further and keep the things ready for next run !!!"

write-host
write-host
Pause 1
write-host
write-host


$PriSMTP = Read-Host "Type the Primary SMTP address of End User"
$StartDate = Read-Host "Enter the Start date in MM/DD/YYYY Format"
$EndDate = Read-Host "Enter the End date in MM/DD/YYYY Format"
$OOOMsgInt = Read-Host "Enter the Out of office INTERNAL message"
$OOOMsgExt = Read-Host "Enter the Out of office EXTERNAL message"
Set-MailboxAutoReplyConfiguration -Identity "$PriSMTP" –AutoReplyState Scheduled –StartTime "$StartDate" –EndTime "$EndDate" –ExternalMessage "$OOOMsgExt" –InternalMessage "$OOOMsgInt"
 
write-host -ForegroundColor Yellow "The Out of Office has been set successfully now !!!"

Sleep 5

write-host
write-host

write-host  -ForegroundColor Magenta ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo                                        
write-host -ForegroundColor Yellow "Now I will display the result to you, please verify it!!!"

write-host  -ForegroundColor Magenta ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo                    

write-host
write-host

Sleep 5

Get-mailbox $PriSMTP | get-MailboxAutoReplyConfiguration 

write-host -ForegroundColor Yellow "Hope you've verified the result now, please update end user !!!"


