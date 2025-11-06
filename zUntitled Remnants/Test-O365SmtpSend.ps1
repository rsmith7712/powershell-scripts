# Test-O365SmtpSend.ps1
<#
.SYNOPSIS
  One-shot PowerShell test-send (clean TLS 1.2, visible errors)

.EXAMPLE
  .\Test-O365SmtpSend.ps1 -Username 'userA@domain.com' -From 'userA@domain.com' -To 'userB@domain.com' -Verbose


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
