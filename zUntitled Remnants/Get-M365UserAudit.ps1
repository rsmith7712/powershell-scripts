# Get-M365UserAudit.ps1
<#
.SYNOPSIS
  Audits an Entra ID / M365 user + mailbox (SMTP AUTH, Security Defaults, etc.),
  with verbose output, transcript logging, CSV export, and selectable Graph auth flow.

  Adds:
  -Global Admin credential prompt
  -Auto-install/import of modules
  -Clean, colorized outputs
  -Csv switch to write results to files
  -OutDir (default C:\Temp\Logs) and timestamped filename prefix
  -Separate CSVs for User, Mailbox, CAS/Protocols, Licensing, Auth Methods, and the SMTP Verdict

  Common Error Solution:
    -Write-Warning "Could not install ${Name}: $($_)"

.EXAMPLE
    .\Get-M365UserAudit.ps1 -UserPrincipalName user@domain.com
      [-GraphAuth Browser|DeviceCode] [-Csv] [-OutDir C:\Temp\Logs] [-TenantId <tenantGuidOrDomain>] [-Verbose]

.OUTPUTS
  Save as Get-M365UserAudit.ps1, then run for example:
  .\Get-M365UserAudit.ps1 -UserPrincipalName user@domain.com -GraphAuth Browser -Csv -Verbose -OutDir C:\Temp\Logs

  or (device code with automatic one-time retry):
  .\Get-M365UserAudit.ps1 -UserPrincipalName user@domain.com -GraphAuth DeviceCode -Csv -Verbose -OutDir C:\Temp\Logs

  #>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$UserPrincipalName,

  [ValidateSet('Browser','DeviceCode')]
  [string]$GraphAuth = 'Browser',

  [switch]$Csv,

  [string]$OutDir = 'C:\Temp\Logs',

  # Optional: set your tenant to avoid cross-tenant prompts (GUID or verified domain)
  [string]$TenantId
)

# ---------- Preferences ----------
$VerbosePreference       = 'Continue'
$ErrorActionPreference   = 'Stop'
$ProgressPreference      = 'SilentlyContinue'

# ---------- Helpers ----------
function Ensure-Module {
  param([Parameter(Mandatory)][string]$Name)
  Write-Verbose "Checking for module ${Name}..."
  if (-not (Get-Module -ListAvailable -Name $Name)) {
    try {
      Write-Host "Installing module ${Name}..." -ForegroundColor Cyan
      Install-Module $Name -Scope CurrentUser -Force -ErrorAction Stop
    } catch {
      Write-Warning "Could not install ${Name}: $($_)"
    }
  }
  Import-Module $Name -ErrorAction Stop | Out-Null
  Write-Verbose "Module ${Name} imported."
}

function Write-Section { param([string]$Title) Write-Host "`n=== $Title ===" -ForegroundColor Cyan }
#function Bool-Icon   { param([bool]$Value) if ($Value) { '✅' } else { '❌' } }

# ---------- Logging / Transcript ----------
if (-not (Test-Path $OutDir)) { New-Item -Path $OutDir -ItemType Directory -Force | Out-Null }
$TimeStamp   = (Get-Date).ToString('yyyy-MM-dd HHmm')   # screen
$TimeStampFN = (Get-Date).ToString('yyyy-MM-dd_HHmm')   # filename-safe
$LogFile     = Join-Path $OutDir ("Get-M365UserAudit_{0}.log" -f $TimeStampFN)
$FilePrefix  = "{0}__{1}" -f $TimeStampFN, ($UserPrincipalName -replace '[^a-zA-Z0-9@._-]','_')

Write-Host "Starting transcript: $LogFile" -ForegroundColor Yellow
try { Start-Transcript -Path $LogFile -Append | Out-Null } catch { Write-Warning "Transcript could not be started: $($_.Exception.Message)" }

Write-Host "Starting audit for $UserPrincipalName @ $TimeStamp" -ForegroundColor Green
Write-Verbose "Output directory: $OutDir"
if ($TenantId) { Write-Verbose "Target tenant: $TenantId" }
if ($Csv)      { Write-Host "CSV output enabled. Directory: ${OutDir}" -ForegroundColor Yellow }

# ---------- Modules ----------
Ensure-Module Microsoft.Graph
Ensure-Module ExchangeOnlineManagement
try { Import-Module Microsoft.Graph.Authentication -ErrorAction Stop | Out-Null } catch { Write-Verbose "Graph Authentication submodule not found; proceeding." }

# ---------- Connect: Microsoft Graph ----------
$graphScopes = @(
  'User.Read.All',
  'Directory.Read.All',
  'Policy.Read.All',
  'AuditLog.Read.All',
  'UserAuthenticationMethod.Read.All'  # <-- required to read other users’ auth methods
)
try {
  if ($GraphAuth -eq 'Browser') {
    Write-Host "Connecting to Microsoft Graph (interactive browser)..." -ForegroundColor Yellow
    if ($TenantId) { Connect-MgGraph -Scopes $graphScopes -TenantId $TenantId -NoWelcome | Out-Null }
    else           { Connect-MgGraph -Scopes $graphScopes                -NoWelcome | Out-Null }
  } else {
    Write-Host "Connecting to Microsoft Graph (device code)..." -ForegroundColor Yellow
    try {
      if ($TenantId) { Connect-MgGraph -Scopes $graphScopes -TenantId $TenantId -UseDeviceCode -NoWelcome | Out-Null }
      else           { Connect-MgGraph -Scopes $graphScopes                -UseDeviceCode -NoWelcome | Out-Null }
    } catch {
      if ($_.Exception.Message -match 'Authentication timed out') {
        Write-Warning "Device code timed out after 120s. Retrying once..."
        if ($TenantId) { Connect-MgGraph -Scopes $graphScopes -TenantId $TenantId -UseDeviceCode -NoWelcome | Out-Null }
        else           { Connect-MgGraph -Scopes $graphScopes                -UseDeviceCode -NoWelcome | Out-Null }
      } else { throw }
    }
  }

  $selectProfile = Get-Command Select-MgProfile -ErrorAction SilentlyContinue
  if ($selectProfile) {
    Select-MgProfile -Name 'v1.0'
    Write-Host "Graph profile set to v1.0." -ForegroundColor Green
  } else {
    Write-Host "Select-MgProfile not available; proceeding with default profile." -ForegroundColor Yellow
  }

  Write-Host "Connected to Graph." -ForegroundColor Green
}
catch {
  Write-Error "Failed to connect to Graph. $($_.Exception.Message)"
  try { Stop-Transcript | Out-Null } catch {}
  return
}

# ---------- Connect: Exchange Online ----------
Write-Host "Connecting to Exchange Online (interactive web sign-in)..." -ForegroundColor Yellow
$GaUpn = Read-Host "Enter Global Admin UPN (e.g., admin@contoso.com)"
try {
  if ($TenantId) { Connect-ExchangeOnline -UserPrincipalName $GaUpn -Organization $TenantId -ShowBanner:$false | Out-Null }
  else           { Connect-ExchangeOnline -UserPrincipalName $GaUpn                 -ShowBanner:$false | Out-Null }
  Write-Host "Connected to Exchange Online." -ForegroundColor Green
} catch {
  Write-Error "Failed to connect to Exchange Online. $($_.Exception.Message)"
  try { Disconnect-MgGraph | Out-Null } catch {}
  try { Stop-Transcript | Out-Null } catch {}
  return
}

# ---------- Queries ----------
try {
  # Resolve UPN -> GUID
  Write-Host "Resolving user by UPN via Graph filter..." -ForegroundColor Gray
  $resolvedUser = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'" -ConsistencyLevel eventual -CountVariable _ | Select-Object -First 1
  if (-not $resolvedUser) { throw "User '$UserPrincipalName' not found in Graph." }
  $userId = $resolvedUser.Id

  Write-Host "Querying Graph user object..." -ForegroundColor Gray
  $user = Get-MgUser -UserId $userId -Property `
    Id,UserPrincipalName,DisplayName,Mail,AccountEnabled,UserType,CreatedDateTime,OnPremisesSyncEnabled,ProxyAddresses,AssignedLicenses,AssignedPlans,SignInActivity

  # Auth methods (resilient: handle 403 gracefully)
  Write-Host "Querying Graph auth methods + tenant security defaults..." -ForegroundColor Gray
  $authMethods = $null
  $authSummary = $null
  try {
    $authMethods = Get-MgUserAuthenticationMethod -UserId $userId -ErrorAction Stop
    $authSummary = [pscustomobject]@{
      FIDO2            = ($authMethods | Where-Object { $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.fido2AuthenticationMethod' }).Count
      AuthenticatorApp = ($authMethods | Where-Object { $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.microsoftAuthenticatorAuthenticationMethod' }).Count
      Phone            = ($authMethods | Where-Object { $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.phoneAuthenticationMethod' }).Count
      Email            = ($authMethods | Where-Object { $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.emailAuthenticationMethod' }).Count
      TAP              = ($authMethods | Where-Object { $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.temporaryAccessPassAuthenticationMethod' }).Count
    }
  } catch {
    if ($_.Exception.Message -match '403' -or $_.Exception.Message -match 'accessDenied') {
      Write-Warning "Graph denied access to user auth methods. Add/consent scope: UserAuthenticationMethod.Read.All"
      $authSummary = [pscustomobject]@{ FIDO2='N/A'; AuthenticatorApp='N/A'; Phone='N/A'; Email='N/A'; TAP='N/A' }
    } else { throw }
  }

  $secDefaults = Get-MgPolicyIdentitySecurityDefaultEnforcementPolicy

  Write-Host "Querying Exchange Online mailbox and CAS settings..." -ForegroundColor Gray
  $mbx    = Get-EXOMailbox -Identity $UserPrincipalName -Properties PrimarySmtpAddress,RecipientTypeDetails,EmailAddresses,ForwardingSmtpAddress,DeliverToMailboxAndForward
  $casMbx = Get-EXOCASMailbox -Identity $UserPrincipalName -Properties SmtpClientAuthenticationDisabled,PopEnabled,ImapEnabled,MAPIEnabled,OWAEnabled,ActiveSyncEnabled
  $orgTx  = Get-TransportConfig | Select-Object SmtpClientAuthenticationDisabled

  # ---------- Console Output ----------
  Write-Section "USER (Entra ID)"
  $user | Select-Object DisplayName,UserPrincipalName,AccountEnabled,UserType,CreatedDateTime,OnPremisesSyncEnabled | Format-List

  Write-Section "MAIL / ADDRESSING"
  $user | Select-Object Mail,@{n='ProxyAddresses';e={$_.ProxyAddresses -join '; '}} | Format-List

  Write-Section "LICENSING"
  [pscustomobject]@{ AssignedLicenses = ($user.AssignedLicenses.SkuId -join ', ') } | Format-List
  if ($user.AssignedPlans) {
    $user.AssignedPlans | Select-Object Service,CapabilityStatus,AssignedDateTime | Sort-Object Service | Format-Table -AutoSize
  }

  Write-Section "SIGN-IN ACTIVITY (last)"
  if ($user.SignInActivity) {
    $user.SignInActivity | Select-Object LastSignInDateTime,LastNonInteractiveSignInDateTime,LastSignInRequestId | Format-List
  } else {
    Write-Host "No sign-in activity available in this view."
  }

  Write-Section "EXCHANGE MAILBOX"
  $mbx | Select-Object PrimarySmtpAddress,RecipientTypeDetails,ForwardingSmtpAddress,DeliverToMailboxAndForward | Format-List
  Write-Host "Aliases (EmailAddresses):"
  $mbx.EmailAddresses | Sort-Object

  Write-Section "SMTP AUTH STATUS"
  [pscustomobject]@{
    Org_SmtpClientAuthDisabled     = $orgTx.SmtpClientAuthenticationDisabled
    Mailbox_SmtpClientAuthDisabled = $casMbx.SmtpClientAuthenticationDisabled
  } | Format-List

  Write-Section "CLIENT PROTOCOLS (CAS)"
  $casMbx | Select-Object OWAEnabled,MAPIEnabled,ImapEnabled,PopEnabled,ActiveSyncEnabled | Format-List

  Write-Section "SECURITY DEFAULTS (Tenant)"
  [pscustomobject]@{ IsEnabled = $secDefaults.IsEnabled } | Format-List

  Write-Section "AUTH METHODS (Registered in Entra)"
  $authSummary | Format-List

  # ---------- Verdict ----------
  $orgSmtpDisabled   = $orgTx.SmtpClientAuthenticationDisabled
  $mbxSmtpDisabled   = $casMbx.SmtpClientAuthenticationDisabled
  $isUserMailbox     = ($mbx.RecipientTypeDetails -eq 'UserMailbox')
  $secDefaultsOn     = $secDefaults.IsEnabled

  $smtpAuthAllowed = (-not $orgSmtpDisabled) -and (-not $mbxSmtpDisabled) -and $isUserMailbox
  $mfaBlocksSmtp   = $secDefaultsOn
  $smtpReady       = $smtpAuthAllowed -and (-not $mfaBlocksSmtp) -and $user.AccountEnabled

  Write-Section "SMTP READINESS VERDICT"
  $verdict = [pscustomobject]@{
    SMTP_Auth_Allowed_Org       = (-not $orgSmtpDisabled)
    SMTP_Auth_Allowed_Mailbox   = (-not $mbxSmtpDisabled)
    Mailbox_Is_UserMailbox      = $isUserMailbox
    SecurityDefaults_Off        = (-not $secDefaultsOn)
    User_Account_Enabled        = $user.AccountEnabled
    RESULT_Ready_for_SMTP587    = $smtpReady
    Notes                       = "OrgDisabled=$orgSmtpDisabled; MbxDisabled=$mbxSmtpDisabled; SecDefaultsOn=$secDefaultsOn"
  }
  $verdict | Format-List

  # ---------- CSV Exports ----------
  if ($Csv) {
    $userRow = [pscustomobject]@{
      DisplayName              = $user.DisplayName
      UserPrincipalName        = $user.UserPrincipalName
      Mail                     = $user.Mail
      AccountEnabled           = $user.AccountEnabled
      UserType                 = $user.UserType
      CreatedDateTime          = $user.CreatedDateTime
      OnPremisesSyncEnabled    = $user.OnPremisesSyncEnabled
      ProxyAddresses           = ($user.ProxyAddresses -join ';')
      LastSignInDateTime       = $user.SignInActivity.LastSignInDateTime
      LastNonInteractiveSignIn = $user.SignInActivity.LastNonInteractiveSignInDateTime
    }
    $userRow | Export-Csv -Path (Join-Path $OutDir "${FilePrefix}__user.csv") -NoTypeInformation -Encoding UTF8 -Force

    [pscustomobject]@{ AssignedLicensesSkuIds = ($user.AssignedLicenses.SkuId -join ';') } |
      Export-Csv -Path (Join-Path $OutDir "${FilePrefix}__licensing.csv") -NoTypeInformation -Encoding UTF8 -Force
    if ($user.AssignedPlans) {
      $user.AssignedPlans |
        Select-Object Service,CapabilityStatus,AssignedDateTime |
        Export-Csv -Path (Join-Path $OutDir "${FilePrefix}__assignedPlans.csv") -NoTypeInformation -Encoding UTF8 -Force
    }

    $mbxRow = [pscustomobject]@{
      PrimarySmtpAddress        = $mbx.PrimarySmtpAddress
      RecipientTypeDetails      = $mbx.RecipientTypeDetails
      ForwardingSmtpAddress     = $mbx.ForwardingSmtpAddress
      DeliverToMailboxAndForward= $mbx.DeliverToMailboxAndForward
      EmailAddresses            = ($mbx.EmailAddresses | Sort-Object | Out-String).Trim()
    }
    $mbxRow  | Export-Csv -Path (Join-Path $OutDir "${FilePrefix}__mailbox.csv") -NoTypeInformation -Encoding UTF8 -Force

    $casRow = [pscustomobject]@{
      Org_SmtpClientAuthDisabled     = $orgTx.SmtpClientAuthenticationDisabled
      Mailbox_SmtpClientAuthDisabled = $casMbx.SmtpClientAuthenticationDisabled
      OWAEnabled                     = $casMbx.OWAEnabled
      MAPIEnabled                    = $casMbx.MAPIEnabled
      ImapEnabled                    = $casMbx.ImapEnabled
      PopEnabled                     = $casMbx.PopEnabled
      ActiveSyncEnabled              = $casMbx.ActiveSyncEnabled
    }
    $casRow | Export-Csv -Path (Join-Path $OutDir "${FilePrefix}__cas.csv") -NoTypeInformation -Encoding UTF8 -Force

    [pscustomobject]@{ SecurityDefaultsEnabled = $secDefaults.IsEnabled } |
      Export-Csv -Path (Join-Path $OutDir "${FilePrefix}__securityDefaults.csv") -NoTypeInformation -Encoding UTF8 -Force
    $authSummary | Export-Csv -Path (Join-Path $OutDir "${FilePrefix}__authMethods.csv") -NoTypeInformation -Encoding UTF8 -Force
    $verdict     | Export-Csv -Path (Join-Path $OutDir "${FilePrefix}__verdict.csv") -NoTypeInformation -Encoding UTF8 -Force

    Write-Host "`nCSV files written to ${OutDir} (prefix ${FilePrefix})." -ForegroundColor Green
  }

} catch {
  Write-Error "Audit failed: $($_.Exception.Message)"
} finally {
  Write-Verbose "Disconnecting sessions..."
  try { Disconnect-ExchangeOnline -Confirm:$false | Out-Null } catch {}
  try { Disconnect-MgGraph | Out-Null } catch {}
  try { Stop-Transcript | Out-Null } catch {}
  Write-Verbose "All done."
}
