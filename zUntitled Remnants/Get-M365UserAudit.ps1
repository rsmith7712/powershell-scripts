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
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$UserPrincipalName,

  [switch]$Csv,

  [string]$OutDir = 'C:\Temp\Logs'
)

# Make verbose messages print without requiring -Verbose
$VerbosePreference = 'Continue'
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

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

function Write-Section {
  param([string]$Title)
  Write-Host "`n=== $Title ===" -ForegroundColor Cyan
}

function Bool-Icon { param([bool]$Value) if ($Value) { '✅' } else { '❌' } }

# ----- Logging / Transcript -----
if (-not (Test-Path $OutDir)) {
  Write-Verbose "Creating output directory $OutDir"
  New-Item -Path $OutDir -ItemType Directory -Force | Out-Null
}

# Build a filesystem-safe timestamp: "YYYY-MM-DD HHmm"
$TimeStamp   = (Get-Date).ToString('yyyy-MM-dd HHmm')
$TimeStampFN = $TimeStamp -replace '[:/\\]','-' -replace ' ','_'
$LogFile     = Join-Path $OutDir ("Get-M365UserAudit_{0}.log" -f $TimeStampFN)

Write-Host "Starting transcript: $LogFile" -ForegroundColor Yellow
try { Start-Transcript -Path $LogFile -Append | Out-Null } catch { Write-Warning "Transcript could not be started: $($_.Exception.Message)" }

Write-Host "Starting audit for $UserPrincipalName ..." -ForegroundColor Green

# ----- Modules -----
Ensure-Module Microsoft.Graph
Ensure-Module ExchangeOnlineManagement
$HasMSOnline = $false
if (Get-Module -ListAvailable MSOnline) { $HasMSOnline = $true; Import-Module MSOnline -ErrorAction SilentlyContinue | Out-Null; Write-Verbose "MSOnline found and imported." }
else { Write-Verbose "MSOnline module not found; legacy per-user MFA view will be skipped." }

# ----- CSV prep -----
$pref = "{0}__{1}" -f $TimeStampFN, ($UserPrincipalName -replace '[^a-zA-Z0-9@._-]','_')
if ($Csv) {
  Write-Host "CSV output enabled. Directory: ${OutDir}" -ForegroundColor Yellow
}

# -------------------- Connect Microsoft Graph (delegated) --------------------
Write-Host "Connecting to Microsoft Graph (Device Code prompt will appear)..." -ForegroundColor Yellow
$graphScopes = @('User.Read.All','Directory.Read.All','Policy.Read.All','AuditLog.Read.All')
try {
  # NOTE: Graph does not accept PSCredential for delegated sign-in; use device code for a guaranteed console prompt
  Connect-MgGraph -Scopes $graphScopes -UseDeviceCode -NoWelcome | Out-Null
  Select-MgProfile -Name 'v1.0'
  Write-Host "Connected to Graph." -ForegroundColor Green
} catch {
  Write-Error "Failed to connect to Graph. $($_.Exception.Message)"
  Stop-Transcript | Out-Null
  return
}

# -------------------- Connect Exchange Online --------------------
Write-Host "Connecting to Exchange Online (interactive web sign-in)..." -ForegroundColor Yellow
# Prompt for GA UPN to steer EXO sign-in window to the right account
$GaUpn = Read-Host "Enter Global Admin UPN (e.g., admin@contoso.com)"
try {
  # Modern EXO uses interactive web auth; -UserPrincipalName hints the login username
  Connect-ExchangeOnline -UserPrincipalName $GaUpn -ShowBanner:$false | Out-Null
  Write-Host "Connected to Exchange Online." -ForegroundColor Green
} catch {
  Write-Error "Failed to connect to Exchange Online. $($_.Exception.Message)"
  try { Disconnect-MgGraph | Out-Null } catch {}
  Stop-Transcript | Out-Null
  return
}

# -------------------- (Optional) Connect MSOnline for legacy per-user MFA --------------------
$MsolConnected = $false
if ($HasMSOnline) {
  try {
    Write-Host "Connecting to MSOnline (legacy per-user MFA view)..." -ForegroundColor Yellow
    # MSOnline DOES support PSCredential; prompt explicitly
    $GlobalAdminCred = Get-Credential -Message "Enter Global Admin credentials (for MSOnline legacy API)"
    Connect-MsolService -Credential $GlobalAdminCred -ErrorAction Stop
    $MsolConnected = $true
    Write-Host "Connected to MSOnline." -ForegroundColor Green
  } catch {
    Write-Warning "MSOnline connection failed; legacy per-user MFA state will be skipped. $($_.Exception.Message)"
  }
}

# -------------------- Queries --------------------
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

  # -------------------- Console Output --------------------
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

  # -------------------- Verdict --------------------
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

  # -------------------- CSV Exports --------------------
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
    $userRow | Export-Csv -Path (Join-Path $OutDir "${pref}__user.csv") -NoTypeInformation -Encoding UTF8 -Force

    # licensing / plans
    [pscustomobject]@{ AssignedLicensesSkuIds = ($user.AssignedLicenses.SkuId -join ';') } |
      Export-Csv -Path (Join-Path $OutDir "${pref}__licensing.csv") -NoTypeInformation -Encoding UTF8 -Force
    if ($user.AssignedPlans) {
      $user.AssignedPlans | Select-Object Service,CapabilityStatus,AssignedDateTime |
        Export-Csv -Path (Join-Path $OutDir "${pref}__assignedPlans.csv") -NoTypeInformation -Encoding UTF8 -Force
    }

    # mailbox
    $mbxRow = [pscustomobject]@{
      PrimarySmtpAddress        = $mbx.PrimarySmtpAddress
      RecipientTypeDetails      = $mbx.RecipientTypeDetails
      ForwardingSmtpAddress     = $mbx.ForwardingSmtpAddress
      DeliverToMailboxAndForward= $mbx.DeliverToMailboxAndForward
      EmailAddresses            = ($mbx.EmailAddresses | Sort-Object | Out-String).Trim()
    }
    $mbxRow  | Export-Csv -Path (Join-Path $OutDir "${pref}__mailbox.csv") -NoTypeInformation -Encoding UTF8 -Force

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
    $casRow | Export-Csv -Path (Join-Path $OutDir "${pref}__cas.csv") -NoTypeInformation -Encoding UTF8 -Force

    # auth methods + security defaults + verdict
    $authSummary | Export-Csv -Path (Join-Path $OutDir "${pref}__authMethods.csv") -NoTypeInformation -Encoding UTF8 -Force
    [pscustomobject]@{ SecurityDefaultsEnabled = $secDefaults.IsEnabled } |
      Export-Csv -Path (Join-Path $OutDir "${pref}__securityDefaults.csv") -NoTypeInformation -Encoding UTF8 -Force
    $verdict | Export-Csv -Path (Join-Path $OutDir "${pref}__verdict.csv") -NoTypeInformation -Encoding UTF8 -Force

    Write-Host "`nCSV files written to ${OutDir} (prefix ${pref})." -ForegroundColor Green
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