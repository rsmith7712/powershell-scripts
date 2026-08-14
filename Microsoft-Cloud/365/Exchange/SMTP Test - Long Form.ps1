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
    SMTP Test - Long Form.ps1

.DESCRIPTION
    Sends a test email via Send-MailMessage with fully documented SMTP parameters (server, port, from, to, subject, body).

.FUNCTIONALITY
    Sends a documented SMTP test email.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$SmtpServer = 'mysmtp.com' # SMTP Server name
$Port = 25                 # SMTP server port number – default is 25
$From = 'user@example.com'  # from address - doesn't have to be valid, just in the format user@domain.ext and something your mail filter will not block
$To = 'user@domain.ext'    # email address to send test to 
$Subject = 'test'          # email subject
$Body = 'test'             # email body
 
Send-MailMessage -SmtpServer $SmtpServer -Port $Port -From $From -To $To -Subject $Subject -Body $Body 