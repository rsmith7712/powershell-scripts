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
    send.external.admin2.ps1

.DESCRIPTION
    Sends an external test email through the Microsoft 365 mail-protection SMTP endpoint (hybrid relay test).

.FUNCTIONALITY
    Sends an external SMTP relay test email.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$SmtpServer = 'domain-com.mail.protection.outlook.com' 
# SMTP Server name domain.mail.onmicrosoft.com domain-com.mail.protection.outlook.com
$Port = 25                
# SMTP server port number – default is 25
$From = 'ps5@example.com'  
# from address - doesn't have to be valid, just in the format user@domain.ext and something your mail filter will not block
$To = 'user@company.com'   
# email address to send test to 
$Subject = 'test from ps5 hybrid'         
# email subject
$Body = 'test'             
# email body
 
Send-MailMessage -SmtpServer $SmtpServer -Port $Port -From $From -To $To -Subject $Subject -Body $Body 