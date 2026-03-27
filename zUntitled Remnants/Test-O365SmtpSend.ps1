# LEGAL
<# LICENSE
    MIT License, Copyright 2025 Richard Smith

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
    Test-O365SmtpSend.ps1

.DESCRIPTION
    One-shot PowerShell test-send (clean TLS 1.2, visible errors)

.FUNCTIONALITY
    This script is designed to test sending an email via Office 365's SMTP
    server using PowerShell. It allows the user to specify the SMTP server,
    port, username, sender and recipient email addresses, subject, and body
    of the email. The script also forces the use of TLS 1.2 for secure
    communication with the SMTP server.

    The script can be modified to include additional functionality as needed.

    .EXAMPLE
    .\Test-O365SmtpSend.ps1 -Username 'userA@domain.com' -From 'userA@domain.com' -To 'userB@domain.com' -Verbose

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>

[CmdletBinding()]
param(
  [string]$SmtpServer = 'smtp.office365.com',
  [int]$Port = 587,
  [Parameter(Mandatory=$true)][string]$Username,
  [Parameter(Mandatory=$true)][string]$From,
  [Parameter(Mandatory=$true)][string]$To,
  [string]$Subject = 'SMTP test via Office 365',
  [string]$Body = 'Hello from SMTP 587 + STARTTLS.',
  [securestring]$Password
)

if (-not $Password) { $Password = Read-Host "Enter password for $Username" -AsSecureString }
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
  [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
)

# Force TLS 1.2+
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

try {
  $msg = New-Object System.Net.Mail.MailMessage($From,$To,$Subject,$Body)
  $smtp = New-Object System.Net.Mail.SmtpClient($SmtpServer,$Port)
  $smtp.EnableSsl = $true     # STARTTLS on 587
  $smtp.Credentials = New-Object System.Net.NetworkCredential($Username,$plain)
  Write-Verbose "Sending..."
  $smtp.Send($msg)
  Write-Host "✅ Sent OK to $To" -ForegroundColor Green
} catch {
  Write-Error "Send failed: $($_.Exception.Message)"
} finally {
  if ($msg) { $msg.Dispose() }
}