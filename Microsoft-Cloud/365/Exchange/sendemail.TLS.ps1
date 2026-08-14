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
    sendemail.TLS.ps1

.DESCRIPTION
    Sends a test email over TLS using an imported client certificate to the Microsoft 365 mail-protection SMTP endpoint.

.FUNCTIONALITY
    Tests TLS SMTP relay delivery with a client certificate.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$pfxFile = "C:\Cert\srvportal.example.com.pfx"
$pfxPass = ''
$pfxBytes = Get-Content -path $pfxFile -encoding Byte -ErrorAction:SilentlyContinue
$X509Cert = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2
$X509Cert.Import([byte[]]$pfxBytes, $pfxPass,"Exportable,PersistKeySet")

# Build SMTP properties
#$smtpServer = 'domain-com.mail.protection.outlook.com'
$smtpServer = '0.0.0.0'
$smtpPort = '25'
$smtp = New-Object Net.Mail.SmtpClient($smtpServer,$smtpPort)
$smtp.ClientCertificates.Add($X509Cert)
$smtp.EnableSSL = $true

# Compose message
$emailMessage = New-Object System.Net.Mail.MailMessage
$emailMessage.From = 'dyoung@example.com'
#$emailMessage.To.Add('user@company.com')
$emailMessage.To.Add('hoh@example.com')
$emailMessage.Subject = ('SMTP Relay (TLS) - ' + (Get-Date -Format g))
$emailMessage.Body = 'This is a test email using SMTP Relay (TLS)'

# Send the message
$smtp.Send($emailMessage)

#domain.mail.protection.outlook.com	0.0.0.0
