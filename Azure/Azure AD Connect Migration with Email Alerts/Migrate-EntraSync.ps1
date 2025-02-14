# PowerShell Script to Migrate Microsoft Azure AD Connect from Server1 to Server2
# Includes optional email alerts for sync failures

# Define Variables
$AzureADConnectURL = "https://aka.ms/aadconnect"
$AzureADConnectInstaller = "AzureADConnect.msi"
$EnableEmailAlerts = $false

# Ask User If They Want Email Alerts
$EnableEmail = Read-Host "Do you want to enable email alerts for sync failures? (Yes/No)"
if ($EnableEmail -match "^(Y|y|Yes|yes)$") {
    $EnableEmailAlerts = $true
    $SMTPServer = Read-Host "Enter SMTP Server (e.g., smtp.office365.com)"
    $SMTPPort = Read-Host "Enter SMTP Port (default is 587)"
    $SenderEmail = Read-Host "Enter Sender Email (e.g., admin@domain.com)"
    $RecipientEmail = Read-Host "Enter Recipient Email for Alerts"
    $SMTPUsername = Read-Host "Enter SMTP Username"
    $SMTPPassword = Read-Host "Enter SMTP Password" -AsSecureString
}

# Function to Send Email Alert
function Send-EmailAlert {
    param (
        [string]$Subject,
        [string]$Body
    )
    
    if ($EnableEmailAlerts -eq $true) {
        $SMTPPasswordUnsecure = [System.Net.NetworkCredential]::new("", $SMTPPassword).Password
        $EmailMessage = @{
            From       = $SenderEmail
            To         = $RecipientEmail
            Subject    = $Subject
            Body       = $Body
            SmtpServer = $SMTPServer
            Port       = $SMTPPort
            UseSsl     = $true
            Credential = New-Object System.Management.Automation.PSCredential ($SMTPUsername, (ConvertTo-SecureString $SMTPPasswordUnsecure -AsPlainText -Force))
        }
        Send-MailMessage @EmailMessage
        Write-Host "Email alert sent to $RecipientEmail." -ForegroundColor Green
    }
}

# Function to Disable Sync on Server1
function Disable-SyncOnServer1 {
    Write-Host "Disabling Sync on Server1..." -ForegroundColor Yellow
    Set-ADSyncScheduler -SyncCycleEnabled $false
    Start-Sleep -Seconds 5
    $status = Get-ADSyncScheduler
    if ($status.SyncCycleEnabled -eq $false) {
        Write-Host "Sync Disabled Successfully on Server1." -ForegroundColor Green
    } else {
        Write-Host "Error Disabling Sync on Server1." -ForegroundColor Red
        Send-EmailAlert -Subject "Azure AD Sync Error on Server1" -Body "Failed to disable sync on Server1."
    }
}

# Function to Download and Install Azure AD Connect on Server2
function Install-AzureADConnect {
    Write-Host "Downloading Azure AD Connect..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $AzureADConnectURL -OutFile $AzureADConnectInstaller
    Write-Host "Installing Azure AD Connect..." -ForegroundColor Yellow
    Start-Process -FilePath msiexec.exe -ArgumentList "/i $AzureADConnectInstaller /quiet /norestart" -Wait
    Write-Host "Azure AD Connect Installed Successfully." -ForegroundColor Green
}

# Function to Configure Azure AD Connect on Server2
function Configure-AzureADConnect {
    Write-Host "Configuring Azure AD Connect on Server2..." -ForegroundColor Yellow
    Start-Process "C:\Program Files\Microsoft Azure AD Sync\AzureADConnect.exe"
    Write-Host "Follow the GUI to complete the configuration. Enable Staging Mode!" -ForegroundColor Cyan
}

# Function to Enable Sync on Server2 and Disable Staging Mode
function Enable-SyncOnServer2 {
    Write-Host "Enabling Sync on Server2..." -ForegroundColor Yellow
    Set-ADSyncScheduler -SyncCycleEnabled $true
    Start-Sleep -Seconds 5
    $status = Get-ADSyncScheduler
    if ($status.SyncCycleEnabled -eq $true) {
        Write-Host "Sync Enabled Successfully on Server2." -ForegroundColor Green
    } else {
        Write-Host "Error Enabling Sync on Server2." -ForegroundColor Red
        Send-EmailAlert -Subject "Azure AD Sync Error on Server2" -Body "Failed to enable sync on Server2."
    }
}

# Function to Uninstall Azure AD Connect from Server1
function Uninstall-AzureADConnect {
    Write-Host "Uninstalling Azure AD Connect from Server1..." -ForegroundColor Yellow
    Start-Process -FilePath "C:\Program Files\Microsoft Azure AD Sync\AzureADConnect.exe" -ArgumentList "/uninstall" -Wait
    Write-Host "Azure AD Connect Uninstalled Successfully from Server1." -ForegroundColor Green
}

# Function to Run a Manual Sync on Server2
function Run-ManualSync {
    Write-Host "Running a Manual Sync on Server2..." -ForegroundColor Yellow
    Start-ADSyncSyncCycle -PolicyType Initial
    Write-Host "Manual Sync Triggered Successfully." -ForegroundColor Green
}

# Function to Verify Sync Status
function Verify-SyncStatus {
    Write-Host "Checking Sync Status..." -ForegroundColor Yellow
    $status = Get-ADSyncScheduler
    if ($status.SyncCycleEnabled -eq $true) {
        Write-Host "Azure AD Sync is running successfully on Server2." -ForegroundColor Green
    } else {
        Write-Host "Warning: Sync is not enabled on Server2!" -ForegroundColor Red
        Send-EmailAlert -Subject "Azure AD Sync Warning" -Body "Sync is not enabled on Server2. Please check immediately."
    }
}

# Main Execution Flow
Write-Host "Starting Azure AD Connect Migration Process..." -ForegroundColor Cyan

# Step 1: Disable Sync on Server1
Disable-SyncOnServer1

# Step 2: Install Azure AD Connect on Server2
Write-Host "Switch to Server2 and run this script from Step 3 onwards." -ForegroundColor Magenta
Pause

# Step 3: Install and Configure Azure AD Connect on Server2
Install-AzureADConnect
Configure-AzureADConnect

# Step 4: Enable Sync on Server2 and Run a Manual Sync
Enable-SyncOnServer2
Run-ManualSync

# Step 5: Uninstall Azure AD Connect from Server1
Write-Host "Switch back to Server1 and run the script from Step 5 onwards." -ForegroundColor Magenta
Pause
Uninstall-AzureADConnect

# Step 6: Verify Final Sync Status
Verify-SyncStatus

Write-Host "Azure AD Connect Migration Completed Successfully!" -ForegroundColor Green
