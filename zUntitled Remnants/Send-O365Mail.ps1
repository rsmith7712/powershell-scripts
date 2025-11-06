# Send-O365Mail.ps1
<#
.SYNOPSIS
  Production PowerShell Sender (retry/backoff + logging to C:\Temp\Logs)

.EXAMPLE
  $sec = Read-Host "Password" -AsSecureString
  .\Send-O365Mail.ps1 -Username 'userA@domain.com' -Password $sec -From 'userA@domain.com' -To 'userB@domain.com' -Subject 'Prod test' -Body 'Hello'

#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$Username,
  [Parameter(Mandatory)][securestring]$Password,
  [Parameter(Mandatory)][string]$From,
  [Parameter(Mandatory)][string]$To,
  [string]$Subject = "[Prod] SMTP send",
  [string]$Body = "Body text",
  [string]$SmtpServer = 'smtp.office365.com',
  [int]$Port = 587,
  [int]$MaxRetries = 3,
  [string]$OutDir = 'C:\Temp\Logs'
)

if (-not (Test-Path $OutDir)) { New-Item -Path $OutDir -ItemType Directory -Force | Out-Null }
$ts   = (Get-Date).ToString('yyyy-MM-dd_HHmm')
$log  = Join-Path $OutDir "SMTP_Send_${ts}.log"
Start-Transcript -Path $log -Append | Out-Null

# TLS 1.2+
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
  [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
)

function Send-MailOnce {
  param([string]$u,[string]$p,[string]$from,[string]$to,[string]$subj,[string]$body,[string]$host,[int]$port)
  $msg = New-Object System.Net.Mail.MailMessage($from,$to,$subj,$body)
  $smtp = New-Object System.Net.Mail.SmtpClient($host,$port)
  $smtp.EnableSsl   = $true
  $smtp.Credentials = New-Object System.Net.NetworkCredential($u,$p)
  try   { $smtp.Send($msg) }
  finally { $msg.Dispose() }
}

$attempt = 0
$sent = $false
while (-not $sent -and $attempt -lt $MaxRetries) {
  $attempt++
  try {
    Write-Host "Attempt #$attempt sending to $To ..." -ForegroundColor Cyan
    Send-MailOnce -u $Username -p $plain -from $From -to $To -subj $Subject -body $Body -host $SmtpServer -port $Port
    Write-Host "✅ Sent OK" -ForegroundColor Green
    $sent = $true
  } catch {
    $err = $_.Exception.Message
    Write-Warning "Attempt #$attempt failed: $err"
    if ($attempt -lt $MaxRetries) {
      $delay = [math]::Pow(2, $attempt)  # 2,4,8...
      Write-Host "Backing off ${delay}s..." -ForegroundColor DarkYellow
      Start-Sleep -Seconds $delay
    } else {
      Write-Error "Giving up after $attempt attempts."
      break
    }
  }
}

Stop-Transcript | Out-Null
if (-not $sent) { exit 1 }
