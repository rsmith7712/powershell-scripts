# PowerShell Script to Migrate Microsoft Azure AD Connect from Server1 to Server2
# Run this script on both servers at appropriate stages

# Define Variables
$AzureADConnectURL = "https://aka.ms/aadconnect"
$AzureADConnectInstaller = "AzureADConnect.msi"

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
