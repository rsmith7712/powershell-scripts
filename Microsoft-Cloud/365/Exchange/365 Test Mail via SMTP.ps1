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
    365 Test Mail via SMTP.ps1

.DESCRIPTION
    Sends a test email through the Office 365 SMTP relay authenticated as a service account.

.FUNCTIONALITY
    Tests Office 365 SMTP relay delivery.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#365 Test Mail via SMTP

# Authenticate as svc-mktgweb
$cred = Get-Credential  # enter svc-mktgweb@domain.co + its password (<password>)

Send-MailMessage `
  -From 'svc-mktgweb@domain.co' `
  -To 'admin@domain.co' `
  -Subject 'Test Email' `
  -Body 'Test SMTP Relay Service' `
  -SmtpServer 'smtp.office365.com' `
  -Credential $cred `
  -UseSsl `
  -Port 587
