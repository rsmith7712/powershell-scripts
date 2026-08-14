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
    m365-fSend-SMTPTest.ps1

.DESCRIPTION
    Sends a test email through the internal SMTP relay using configurable mail parameters (from, to, subject, host, port, SSL).

.FUNCTIONALITY
    Sends a configurable SMTP test email.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#  Mail Report Setup Variables #

[string]$from = "noreply@automation.example.com"
[string]$to = "a-team@example.com"
[string]$subject = "SMTP Mail Test"
[string]$smtphost = "smtpi.example.com"
[int32]$port = "25"
[boolean]$SSL = $false

#[string]$usr = "DOMAINScheduler@example.com"
#[string]$pw = "<password>"
#[string]$usr = "SLC@dmin@example.com"
#[string]$pw = "<password>"
#       Mail the Report        #

function Send-Email {
    param (
        [ValidateSet("TXT","HTML")] 
        [String] $MessageContentType = "HTML"
    )
    $message = New-Object System.Net.Mail.MailMessage
    $mailer = New-Object System.Net.Mail.SmtpClient ($smtphost, $port)
    $mailer.EnableSSL = $SSL
    $mailer.Credentials = New-Object System.Net.NetworkCredential($usr, $pw)
    $message.From = $from
    $message.To.Add($to)
    $message.Subject = $subject
    $message.Body = "----------> !! Testies 123 !! <----------</br></br><A HREF='mailto:a-team@example.com'>Domain Automation Team</A>"
    $message.IsBodyHtml = $True
    $message.DeliveryNotificationOptions = 'OnFailure','OnSuccess'
    $mailer.send(($message))
}
Send-Email