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
    Get-M365User.ps1

.DESCRIPTION
    Retrieves key Microsoft 365 / Entra user details for a specified user principal name via the Microsoft Graph SDK.

.FUNCTIONALITY
    Reports Microsoft 365 user details via Graph.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#Get-M365User.ps1

# 1) Quick Graph-only: key Microsoft 365 / Entra user details

# Requires: Microsoft.Graph PowerShell SDK
#   Install-Module Microsoft.Graph -Scope CurrentUser
# Usage: .\Get-M365User.ps1 -UserPrincipalName svc-mktgweb@domain.co

param(
  [Parameter(Mandatory)]
  [string]$UserPrincipalName
)

Install-Module -Name Microsoft.Graph -Scope AllUsers -ErrorAction Stop -AllowClobber

# Connect (interactive). First run will prompt for consent.
$scopes = @(
  'User.Read.All',
  'Directory.Read.All',
  'Policy.Read.All',
  'AuditLog.Read.All'      # needed only if you use the sign-in logs section
)
Connect-MgGraph -Scopes $scopes | Out-Null
Select-MgProfile -Name "v1.0"

# Core user object
$user = Get-MgUser -UserId $UserPrincipalName -Property Id,UserPrincipalName,DisplayName,AccountEnabled,UserType,CreatedDateTime,Mail,MailNickname,ProxyAddresses,AssignedLicenses,AssignedPlans,OnPremisesSyncEnabled,SignInActivity

# Authentication methods (what the user has registered)
$authMethods = Get-MgUserAuthenticationMethod -UserId $user.Id

# Registered FIDO/Phone/Email methods (short summary)
$authSummary = [pscustomobject]@{
  HasFido2Key          = ($authMethods | Where-Object {$_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.fido2AuthenticationMethod'}).Count -gt 0
  HasMicrosoftAuthenticator = ($authMethods | Where-Object {$_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.microsoftAuthenticatorAuthenticationMethod'}).Count -gt 0
  PhoneMethods         = ($authMethods | Where-Object {$_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.phoneAuthenticationMethod'}).Count
  EmailMethods         = ($authMethods | Where-Object {$_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.emailAuthenticationMethod'}).Count
  TemporaryAccessPass  = ($authMethods | Where-Object {$_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.temporaryAccessPassAuthenticationMethod'}).Count -gt 0
}

# Security Defaults (tenant-wide)
$secDefaults = Get-MgPolicyIdentitySecurityDefaultEnforcementPolicy

# OUTPUT
"=== USER (Entra ID) ==="
$user | Select-Object DisplayName,UserPrincipalName,AccountEnabled,UserType,CreatedDateTime,OnPremisesSyncEnabled |
  Format-List

"=== MAIL / ADDRESSING ==="
$user | Select-Object Mail,MailNickname,@{n='ProxyAddresses';e={$_.ProxyAddresses -join '; '}} | Format-List

"=== LICENSING ==="
"AssignedLicenses (SKU IDs): " + ($user.AssignedLicenses.SkuId -join ', ')
"AssignedPlans (Service/Status):"
$user.AssignedPlans | Select-Object Service,CapabalityStatus,AssignedDateTime | Format-Table -AutoSize

"=== SIGN-IN ACTIVITY (last) ==="
if ($user.SignInActivity) {
  $user.SignInActivity | Select-Object LastSignInDateTime,LastNonInteractiveSignInDateTime,LastSignInRequestId | Format-List
} else {
  "No sign-in activity available (permission/feature dependent)."
}

"=== AUTH METHODS (registered) ==="
$authSummary | Format-List

"=== SECURITY DEFAULTS (tenant) ==="
[pscustomobject]@{
  IsEnabled = $secDefaults.IsEnabled
} | Format-List

Disconnect-MgGraph | Out-Null

# 2) Deep-dive “SMTP/MFA troubleshooting” audit

# Requires:
#   Install-Module Microsoft.Graph -Scope CurrentUser
#   Install-Module ExchangeOnlineManagement -Scope CurrentUser
#   Install-Module MSOnline -Scope CurrentUser   # legacy, for per-user MFA status
# Usage: .\Audit-M365-MailSender.ps1 -UserPrincipalName svc-mktgweb@domain.co

param(
  [Parameter(Mandatory)]
  [string]$UserPrincipalName
)

# --- Connect Microsoft Graph ---
Import-Module Microsoft.Graph -ErrorAction Stop
$graphScopes = @('User.Read.All','Directory.Read.All','Policy.Read.All','AuditLog.Read.All')
Connect-MgGraph -Scopes $graphScopes | Out-Null
Select-MgProfile -Name "v1.0"

# --- Connect Exchange Online ---
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-ExchangeOnline -ShowBanner:$false | Out-Null

# --- (Optional) Connect MSOnline for legacy per-user MFA toggle ---
Import-Module MSOnline -ErrorAction SilentlyContinue
$msolConnected = $false
try { Connect-MsolService -ErrorAction Stop; $msolConnected = $true } catch {}

# --- ENTRA USER ---
$user = Get-MgUser -UserId $UserPrincipalName -Property Id,UserPrincipalName,DisplayName,AccountEnabled,Mail,ProxyAddresses,AssignedLicenses,AssignedPlans,SignInActivity

# --- AUTH METHODS / SECURITY DEFAULTS ---
$authMethods   = Get-MgUserAuthenticationMethod -UserId $user.Id
$secDefaults   = Get-MgPolicyIdentitySecurityDefaultEnforcementPolicy

# --- EXCHANGE ONLINE: mailbox + SMTP AUTH flags ---
$mbx      = Get-EXOMailbox -Identity $UserPrincipalName -Properties PrimarySmtpAddress,RecipientTypeDetails,ForwardingSmtpAddress,DeliverToMailboxAndForward
$casMbx   = Get-EXOCASMailbox -Identity $UserPrincipalName -Properties SmtpClientAuthenticationDisabled,PopEnabled,ImapEnabled,MAPIEnabled,OWAEnabled,ActiveSyncEnabled,Protocols
$orgTrans = Get-TransportConfig | Select-Object SmtpClientAuthenticationDisabled

# --- Legacy per-user MFA status (if MSOnline connected) ---
$legacyMfa = $null
if ($msolConnected) {
  $msolUser  = Get-MsolUser -UserPrincipalName $UserPrincipalName
  $legacyMfa = [pscustomobject]@{
    LegacyMfaState  = $msolUser.StrongAuthenticationRequirements.State
    MethodsCount    = ($msolUser.StrongAuthenticationMethods | Measure-Object).Count
  }
}

# --- SUMMARIZE ---
Write-Host "=== USER ==="
$user | Select DisplayName,UserPrincipalName,AccountEnabled | Format-List

Write-Host "`n=== MAILBOX (EXO) ==="
$mbx | Select PrimarySmtpAddress,RecipientTypeDetails,ForwardingSmtpAddress,DeliverToMailboxAndForward | Format-List

Write-Host "`n=== SMTP AUTH STATUS ==="
[pscustomobject]@{
  Org_SmtpClientAuthDisabled   = $orgTrans.SmtpClientAuthenticationDisabled
  Mailbox_SmtpClientAuthDisabled = $casMbx.SmtpClientAuthenticationDisabled
} | Format-List

Write-Host "`n=== CLIENT PROTOCOLS (CAS) ==="
$casMbx | Select OWAEnabled,MAPIEnabled,ImapEnabled,PopEnabled,ActiveSyncEnabled | Format-List

Write-Host "`n=== PROXY ADDRESSES ==="
($user.ProxyAddresses | Sort-Object) -join "`n"

Write-Host "`n=== SECURITY DEFAULTS (tenant) ==="
[pscustomobject]@{ IsEnabled = $secDefaults.IsEnabled } | Format-List

Write-Host "`n=== AUTH METHODS (registered in Entra) ==="
$authSummary = [pscustomobject]@{
  FIDO2            = ($authMethods | Where-Object {$_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.fido2AuthenticationMethod'}).Count
  AuthenticatorApp = ($authMethods | Where-Object {$_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.microsoftAuthenticatorAuthenticationMethod'}).Count
  Phone            = ($authMethods | Where-Object {$_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.phoneAuthenticationMethod'}).Count
  Email            = ($authMethods | Where-Object {$_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.emailAuthenticationMethod'}).Count
  TAP              = ($authMethods | Where-Object {$_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.temporaryAccessPassAuthenticationMethod'}).Count
}
$authSummary | Format-List

if ($legacyMfa) {
  Write-Host "`n=== LEGACY PER-USER MFA (MSOnline) ==="
  $legacyMfa | Format-List
} else {
  Write-Host "`n(legacy per-user MFA status skipped; MSOnline not connected)"
}

# (Optional) recent sign-in info (useful to see MFA requirement results)
Write-Host "`n=== SIGN-IN ACTIVITY (from user object) ==="
if ($user.SignInActivity) {
  $user.SignInActivity | Select LastSignInDateTime,LastNonInteractiveSignInDateTime,LastSignInRequestId | Format-List
} else {
  Write-Host "No sign-in activity available here. For full logs, query Sign-In logs in Entra ID portal or Graph /auditLogs/signIns."
}

# --- CLEANUP ---
Disconnect-ExchangeOnline -Confirm:$false
Disconnect-MgGraph | Out-Null


#What these scripts tell you (at a glance)
#
#User core: enabled/disabled, UPN, aliases, licensing.
#Mailbox type: user vs shared; forwarding settings.
#SMTP AUTH: org-level **and** mailbox-level flags that block/allow SMTP AUTH.
#Client protocol toggles: OWA/MAPI/IMAP/POP/ActiveSync.
#Security Defaults: on/off (forces MFA regardless of CA).
#Auth methods: what MFA methods are registered (useful to explain unexpected prompts).
#Legacy per-user MFA: Enabled/Enforced/Disabled (the “old” toggle that can still force prompts).
