# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith, user21

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
    AD-PasswordExpiryNotice.v2.ps1

.SYNOPSIS
    Sends password expiration reminder emails to Active Directory users.

.DESCRIPTION
    Queries on-premises Active Directory for enabled users whose passwords are
    approaching expiration based on the domain's default password policy, then
    emails each matching user.

    This public-safe version adds:
    - Parameters instead of hard-coded org values
    - Safer SMTP options (port, SSL/TLS, optional credential)
    - Preview-only mode
    - CSV reporting
    - Better filtering and error handling
    - Support for WhatIf / Confirm

    .NOTES
    This script uses the domain default password policy. Environments using
    Fine-Grained Password Policies may require additional logic to calculate
    the effective policy per user.

    Recommended first test:
    .\AD-PasswordExpiryNotice.v2.ps1 -TestingUsername test.user -PreviewOnly -Verbose

    After that:
    .\AD-PasswordExpiryNotice.v2.ps1 -WhatIf -Verbose

    Then replace the placeholders and do a real run.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [string]$From = 'it-support@example.com',

    [Parameter()]
    [string]$SmtpServer = 'smtp.example.com',

    [Parameter()]
    [int]$SmtpPort = 587,

    [Parameter()]
    [switch]$UseSsl,

    [Parameter()]
    [System.Management.Automation.PSCredential]$SmtpCredential,

    [Parameter()]
    [string]$MailSubject = 'Important Reminder: Your password will expire soon',

    [Parameter()]
    [ValidateRange(1,365)]
    [int]$DaysBeforeExpiry = 5,

    [Parameter()]
    [switch]$PreviewOnly,

    [Parameter()]
    [string]$TestingUsername,

    [Parameter()]
    [string]$SearchBase,

    [Parameter()]
    [string]$CompanyName = 'Example Company',

    [Parameter()]
    [string]$PortalUrl = 'https://mail.example.com',

    [Parameter()]
    [string]$ServiceDeskEmail = 'it-support@example.com',

    [Parameter()]
    [string]$ServiceDeskPhone = '555-0100',

    [Parameter()]
    [string]$ReportPath = '.\\PasswordExpiryReport.csv'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Log {
    param([string]$Message)
    Write-Verbose ("[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message)
}

function Get-PasswordExpiryCandidates {
    param(
        [TimeSpan]$MaxPasswordAge,
        [int]$ReminderWindow,
        [string]$SingleUser,
        [string]$BaseDn
    )

    $properties = @(
        'GivenName',
        'DisplayName',
        'SamAccountName',
        'EmailAddress',
        'Enabled',
        'PasswordLastSet',
        'PasswordExpired',
        'PasswordNeverExpires'
    )

    $adParams = @{ Properties = $properties }
    if ($BaseDn) { $adParams.SearchBase = $BaseDn }

    if ($SingleUser) {
        Write-Log "Collecting single test user: $SingleUser"
        $users = @(Get-ADUser -Identity $SingleUser @adParams)
        $effectiveWindow = 1000
    }
    else {
        Write-Log 'Collecting enabled AD users for password expiry evaluation'
        $users = Get-ADUser -LDAPFilter '(&(objectCategory=person)(objectClass=user))' @adParams
        $effectiveWindow = $ReminderWindow
    }

    $today = Get-Date

    foreach ($user in $users) {
        if (-not $user.Enabled) { continue }
        if ($user.PasswordExpired) { continue }
        if ($user.PasswordNeverExpires) { continue }
        if (-not $user.PasswordLastSet) { continue }
        if ([string]::IsNullOrWhiteSpace($user.EmailAddress)) { continue }

        $expiryDate = $user.PasswordLastSet + $MaxPasswordAge
        $daysLeft = ($expiryDate - $today).Days

        if ($daysLeft -le 0) { continue }
        if ($daysLeft -gt $effectiveWindow) { continue }

        [pscustomobject]@{
            DisplayName          = if ($user.DisplayName) { $user.DisplayName } else { $user.SamAccountName }
            FirstName            = if ($user.GivenName) { $user.GivenName } else { $user.SamAccountName }
            SamAccountName       = $user.SamAccountName
            EmailAddress         = $user.EmailAddress
            PasswordLastSet      = $user.PasswordLastSet
            PasswordExpiresOn    = $expiryDate
            DaysLeft             = $daysLeft
            ReminderWindow       = $effectiveWindow
        }
    }
}

function New-ReminderBody {
    param(
        [Parameter(Mandatory)]$UserRecord,
        [Parameter(Mandatory)][string]$Company,
        [Parameter(Mandatory)][string]$Portal,
        [Parameter(Mandatory)][string]$HelpEmail,
        [Parameter(Mandatory)][string]$HelpPhone
    )

    $expiryDateForEmail = $UserRecord.PasswordExpiresOn.ToString("dddd, MMMM dd yyyy 'at' hh:mm tt")

    @"
<p>$($UserRecord.FirstName),</p>
<p>Your Windows password expires on <strong>$expiryDateForEmail</strong>. You have <strong>$($UserRecord.DaysLeft)</strong> day(s) remaining before it expires.</p>
<p>Please change your password before it expires to avoid interruption of access to your computer, email, VPN, and other company resources.</p>
<p><strong>Working in the office:</strong><br>
Press <strong>Ctrl+Alt+Delete</strong> and select <strong>Change a password</strong>.</p>
<p><strong>Working remotely:</strong><br>
Connect to VPN before changing your password. After changing it, lock your computer and sign back in with the new password so Windows refreshes your credentials.</p>
<p><strong>Mobile devices:</strong><br>
If you use company email on your phone or tablet, update the saved password there after changing it to help avoid account lockouts.</p>
<p><strong>Web access:</strong><br>
If your environment supports it, you may be able to change your password through your webmail or self-service portal: <a href="$Portal">$Portal</a>.</p>
<br>
<p>$Company Service Desk<br>
$HelpPhone<br>
<a href="mailto:$HelpEmail">$HelpEmail</a></p>
"@
}

function Send-ExpiryReminderEmail {
    param(
        [Parameter(Mandatory)][string]$To,
        [Parameter(Mandatory)][string]$FromAddress,
        [Parameter(Mandatory)][string]$Subject,
        [Parameter(Mandatory)][string]$Body,
        [Parameter(Mandatory)][string]$Server,
        [Parameter(Mandatory)][int]$Port,
        [Parameter()][switch]$EnableSsl,
        [Parameter()][System.Management.Automation.PSCredential]$Credential
    )

    $message = New-Object System.Net.Mail.MailMessage
    $message.From = $FromAddress
    $null = $message.To.Add($To)
    $message.Subject = $Subject
    $message.Body = $Body
    $message.IsBodyHtml = $true

    $smtp = New-Object System.Net.Mail.SmtpClient($Server, $Port)
    $smtp.EnableSsl = [bool]$EnableSsl
    $smtp.DeliveryMethod = [System.Net.Mail.SmtpDeliveryMethod]::Network

    if ($Credential) {
        $smtp.Credentials = New-Object System.Net.NetworkCredential(
            $Credential.UserName,
            $Credential.GetNetworkCredential().Password
        )
    }
    else {
        $smtp.UseDefaultCredentials = $true
    }

    try {
        $smtp.Send($message)
    }
    finally {
        $message.Dispose()
        $smtp.Dispose()
    }
}

try {
    Import-Module ActiveDirectory -ErrorAction Stop
    Write-Log 'Loaded ActiveDirectory module'

    $maxPasswordAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge
    Write-Log ("Domain max password age: {0} days" -f [math]::Round($maxPasswordAge.TotalDays, 2))

    $candidates = @(Get-PasswordExpiryCandidates -MaxPasswordAge $maxPasswordAge -ReminderWindow $DaysBeforeExpiry -SingleUser $TestingUsername -BaseDn $SearchBase)
    Write-Log ("Matched {0} user(s) for reminder processing" -f $candidates.Count)

    $results = foreach ($candidate in $candidates) {
        $body = New-ReminderBody -UserRecord $candidate -Company $CompanyName -Portal $PortalUrl -HelpEmail $ServiceDeskEmail -HelpPhone $ServiceDeskPhone
        $action = "Send password expiry reminder to $($candidate.EmailAddress)"
        $status = 'Skipped'
        $detail = ''

        try {
            if ($PreviewOnly) {
                $status = 'PreviewOnly'
                $detail = 'Email not sent because PreviewOnly was specified.'
            }
            elseif ($PSCmdlet.ShouldProcess($candidate.EmailAddress, $action)) {
                Send-ExpiryReminderEmail -To $candidate.EmailAddress -FromAddress $From -Subject $MailSubject -Body $body -Server $SmtpServer -Port $SmtpPort -EnableSsl:$UseSsl -Credential $SmtpCredential
                $status = 'Sent'
                $detail = 'Reminder email sent successfully.'
            }
            else {
                $status = 'WhatIf'
                $detail = 'Email not sent because WhatIf/Confirm prevented execution.'
            }
        }
        catch {
            $status = 'Failed'
            $detail = $_.Exception.Message
        }

        [pscustomobject]@{
            Timestamp         = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            SamAccountName    = $candidate.SamAccountName
            DisplayName       = $candidate.DisplayName
            EmailAddress      = $candidate.EmailAddress
            PasswordExpiresOn = $candidate.PasswordExpiresOn
            DaysLeft          = $candidate.DaysLeft
            Status            = $status
            Detail            = $detail
        }
    }

    $reportDirectory = Split-Path -Path $ReportPath -Parent
    if ($reportDirectory -and -not (Test-Path -LiteralPath $reportDirectory)) {
        $null = New-Item -Path $reportDirectory -ItemType Directory -Force
    }

    $results | Sort-Object DaysLeft, SamAccountName | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
    Write-Log "Report written to $ReportPath"

    $sentCount = @($results | Where-Object Status -eq 'Sent').Count
    $previewCount = @($results | Where-Object Status -eq 'PreviewOnly').Count
    $failedCount = @($results | Where-Object Status -eq 'Failed').Count

    Write-Host "Processed $($results.Count) user(s). Sent: $sentCount | PreviewOnly: $previewCount | Failed: $failedCount"
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
