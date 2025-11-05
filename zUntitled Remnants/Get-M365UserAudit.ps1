# Get-M365UserAudit.ps1
<#
.SYNOPSIS
  Audit key Microsoft 365 user + mailbox details (Entra ID, EXO, SMTP AUTH, MFA flags),
  emit a single SMTP readiness verdict, and (optionally) export CSVs.

  Adds:
  -Global Admin credential prompt
  -Auto-install/import of modules
  -Clean, colorized outputs
  -Csv switch to write results to files
  -OutDir (default C:\Temp\Logs) and timestamped filename prefix
  -Separate CSVs for User, Mailbox, CAS/Protocols, Licensing, Auth Methods, and the SMTP Verdict
    Save as Get-M365UserAudit.ps1, then run:
        .\Get-M365UserAudit.ps1 -UserPrincipalName user@domain.com -Csv -Verbose
    (Optional) -OutDir "D:\Reports"

  Common Error Solution:
    -Write-Warning "Could not install ${Name}: $($_)"

.USAGE
  .\Get-M365UserAudit.ps1 -UserPrincipalName user@domain.com -Csv -Verbose -OutDir C:\Temp\Logs

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

  # Optional: set your tenant to avoid cross-tenant prompts (GUID or domain)
  [string]$TenantId
)

# ---------- Preferences ----------
$VerbosePreference = 'Continue'              # show Write-Verbose without -Verbose flag
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

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

#function Bool-Icon { param([bool]$Value) if ($Value) { '✅' } else { '❌' } }

# ---------- Logging / Transcript ----------
if (-not (Test-Path $OutDir)) { New-Item -Path $OutDir -ItemType Directory -Force | Out-Null }
# "YYYY-MM-DD HHmm" for screen; filesystem-safe "YYYY-MM-DD_HHmm" for filenames
$TimeStamp   = (Get-Date).ToString('yyyy-MM-dd HHmm')
$TimeStampFN = (Get-Date).ToString('yyyy-MM-dd_HHmm')
$LogFile     = Join-Path $OutDir ("Get-M365UserAudit_{0}.log" -f $TimeStampFN)
$FilePrefix  = "{0}__{1}" -f $TimeStampFN, ($UserPrincipalName -replace '[^a-zA-Z0-9@._-]','_')

Write-Host "Starting transcript: $LogFile" -ForegroundColor Yellow
try { Start-Transcript -Path $LogFile -Append | Out-Null } catch { Write-Warning "Transcript could not be started: $($_.Exception.Message)" }

Write-Host "Starting audit for $UserPrincipalName @ $TimeStamp" -ForegroundColor Green
Write-Verbose "Output directory: $OutDir"
if ($TenantId) { Write-Verbose "Target tenant: $TenantId" }

# ---------- Modules ----------
Ensure-Module Microsoft.Graph
Ensure-Module ExchangeOnlineManagement
$HasMSOnline = $false
if (Get-Module -ListAvailable MSOnline) { $HasMSOnline = $true; Import-Module MSOnline -ErrorAction SilentlyContinue | Out-Null; Write-Verbose "MSOnline imported." }
else { Write-Verbose "MSOnline not found; legacy per-user MFA view will be skipped." }

# ---------- CSV prep ----------
if ($Csv) { Write-Host "CSV output enabled. Directory: ${OutDir}" -ForegroundColor Yellow }

# ---------- Connect: Microsoft Graph ----------
# Ensure the Authentication submodule (where Select-MgProfile lives) is present
try { Import-Module Microsoft.Graph.Authentication -ErrorAction Stop } catch { Write-Verbose "Graph auth submodule not found; continuing without explicit import." }

$graphScopes = @('User.Read.All','Directory.Read.All','Policy.Read.All','AuditLog.Read.All')

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

  # Set profile ONLY if the cmdlet exists (prevents crash when submodule/cmdlet is missing)
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
  Stop-Transcript | Out-Null
  return
}

# ---------- Optional: MSOnline (legacy per-user MFA) ----------
$MsolConnected = $false
if ($HasMSOnline) {
  try {
    Write-Host "Connecting to MSOnline (legacy per-user MFA view)..." -ForegroundColor Yellow
    $GlobalAdminCred = Get-Credential -Message "Enter Global Admin credentials (for MSOnline legacy API)"
    Connect-MsolService -Credential $GlobalAdminCred -ErrorAction Stop
    $MsolConnected = $true
    Write-Host "Connected to MSOnline." -ForegroundColor Green
  } catch {
    Write-Warning "MSOnline connection failed; legacy per-user MFA state will be skipped. $($_.Exception.Message)"
  }
}

# ---------- Queries ----------
try {
  Write-Host "Querying Graph user object..." -ForegroundColor Gray
  $user = Get-MgUser -UserId $UserPrincipalName -Property `
    Id,UserPrincipalName,DisplayName,Mail,AccountEnabled,UserType,CreatedDateTime,OnPremisesSyncEnabled,ProxyAddresses,AssignedLicenses,AssignedPlans,SignInActivity

  Write-Host "Querying Graph auth methods + tenant security defaults..." -ForegroundColor Gray
  $authMethods = Get-MgUserAuthenticationMethod -UserId $user.Id
  $secDefaults = Get-MgPolicyIdentitySecurityDefaultEnforcementPolicy

  $authSummary = [pscustomobject]@{
    FIDO2            = ($authMethods | Where-Object {$_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.fido2AuthenticationMethod'}).Count
    AuthenticatorApp = ($authMethods | Where-Object {$_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.microsoftAuthenticatorAuthenticationMethod'}).Count
    Phone            = ($authMethods | Where-Object {$_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.phoneAuthenticationMethod'}).Count
    Email            = ($authMethods | Where-Object {$_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.emailAuthenticationMethod'}).Count
    TAP              = ($authMethods | Where-Object {$_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.temporaryAccessPassAuthenticationMethod'}).Count
  }

  Write-Host "Querying Exchange Online mailbox and CAS settings..." -ForegroundColor Gray
  $mbx    = Get-EXOMailbox -Identity $UserPrincipalName -Properties PrimarySmtpAddress,RecipientTypeDetails,EmailAddresses,ForwardingSmtpAddress,DeliverToMailboxAndForward
  $casMbx = Get-EXOCASMailbox -Identity $UserPrincipalName -Properties SmtpClientAuthenticationDisabled,PopEnabled,ImapEnabled,MAPIEnabled,OWAEnabled,ActiveSyncEnabled
  $orgTx  = Get-TransportConfig | Select-Object SmtpClientAuthenticationDisabled

  # Legacy MFA
  $legacyMfa = $null
  if ($MsolConnected) {
    Write-Host "Querying legacy per-user MFA state..." -ForegroundColor Gray
    $msol = Get-MsolUser -UserPrincipalName $UserPrincipalName -ErrorAction SilentlyContinue
    if ($msol) {
      $legacyMfa = [pscustomobject]@{
        LegacyMfaState = $msol.StrongAuthenticationRequirements.State
        MethodsCount   = ($msol.StrongAuthenticationMethods | Measure-Object).Count
      }
    }
  }

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

  if ($legacyMfa) {
    Write-Section "LEGACY PER-USER MFA (MSOnline)"
    $legacyMfa | Format-List
  } else {
    Write-Host "`n(Legacy per-user MFA state unavailable or MSOnline not connected.)" -ForegroundColor DarkYellow
  }

  # ---------- Verdict ----------
  $orgSmtpDisabled   = $orgTx.SmtpClientAuthenticationDisabled
  $mbxSmtpDisabled   = $casMbx.SmtpClientAuthenticationDisabled
  $isUserMailbox     = ($mbx.RecipientTypeDetails -eq 'UserMailbox')
  $secDefaultsOn     = $secDefaults.IsEnabled
  $legacyMfaState    = $null
  $legacyMfaEnabled  = $false
  if ($legacyMfa) {
    $legacyMfaState   = $legacyMfa.LegacyMfaState
    $legacyMfaEnabled = @('Enabled','Enforced') -contains ($legacyMfa.LegacyMfaState)
  }

  $smtpAuthAllowed = (-not $orgSmtpDisabled) -and (-not $mbxSmtpDisabled) -and $isUserMailbox
  $mfaBlocksSmtp   = $secDefaultsOn -or $legacyMfaEnabled
  $smtpReady       = $smtpAuthAllowed -and (-not $mfaBlocksSmtp) -and $user.AccountEnabled

  Write-Section "SMTP READINESS VERDICT"
  $verdict = [pscustomobject]@{
    SMTP_Auth_Allowed_Org       = (-not $orgSmtpDisabled)
    SMTP_Auth_Allowed_Mailbox   = (-not $mbxSmtpDisabled)
    Mailbox_Is_UserMailbox      = $isUserMailbox
    SecurityDefaults_Off        = (-not $secDefaultsOn)
    Legacy_PerUser_MFA_Off      = (-not $legacyMfaEnabled)
    User_Account_Enabled        = $user.AccountEnabled
    RESULT_Ready_for_SMTP587    = $smtpReady
    Notes                       = "OrgDisabled=$orgSmtpDisabled; MbxDisabled=$mbxSmtpDisabled; SecDefaultsOn=$secDefaultsOn; LegacyMFA=$legacyMfaState"
  }
  $verdict | Format-List

  # ---------- CSV Exports ----------
  if ($Csv) {
    # user
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

    # licensing / plans
    [pscustomobject]@{ AssignedLicensesSkuIds = ($user.AssignedLicenses.SkuId -join ';') } |
      Export-Csv -Path (Join-Path $OutDir "${FilePrefix}__licensing.csv") -NoTypeInformation -Encoding UTF8 -Force
    if ($user.AssignedPlans) {
      $user.AssignedPlans |
        Select-Object Service,CapabilityStatus,AssignedDateTime |
        Export-Csv -Path (Join-Path $OutDir "${FilePrefix}__assignedPlans.csv") -NoTypeInformation -Encoding UTF8 -Force
    }

    # mailbox
    $mbxRow = [pscustomobject]@{
      PrimarySmtpAddress        = $mbx.PrimarySmtpAddress
      RecipientTypeDetails      = $mbx.RecipientTypeDetails
      ForwardingSmtpAddress     = $mbx.ForwardingSmtpAddress
      DeliverToMailboxAndForward= $mbx.DeliverToMailboxAndForward
      EmailAddresses            = ($mbx.EmailAddresses | Sort-Object | Out-String).Trim()
    }
    $mbxRow  | Export-Csv -Path (Join-Path $OutDir "${FilePrefix}__mailbox.csv") -NoTypeInformation -Encoding UTF8 -Force

    # CAS/Protocols
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

    # auth methods + security defaults + verdict
    $authSummary | Export-Csv -Path (Join-Path $OutDir "${FilePrefix}__authMethods.csv") -NoTypeInformation -Encoding UTF8 -Force
    [pscustomobject]@{ SecurityDefaultsEnabled = $secDefaults.IsEnabled } |
      Export-Csv -Path (Join-Path $OutDir "${FilePrefix}__securityDefaults.csv") -NoTypeInformation -Encoding UTF8 -Force
    $verdict | Export-Csv -Path (Join-Path $OutDir "${FilePrefix}__verdict.csv") -NoTypeInformation -Encoding UTF8 -Force

    Write-Host "`nCSV files written to ${OutDir} (prefix ${FilePrefix})." -ForegroundColor Green
  }

} catch {
  Write-Error "Audit failed: $($_.Exception.Message)"
} finally {
  Write-Verbose "Disconnecting sessions..."
  try { Disconnect-ExchangeOnline -Confirm:$false | Out-Null } catch {}
  try { Disconnect-MgGraph | Out-Null } catch {}
  # MSOnline has no disconnect
  try { Stop-Transcript | Out-Null } catch {}
  Write-Verbose "All done."
}
