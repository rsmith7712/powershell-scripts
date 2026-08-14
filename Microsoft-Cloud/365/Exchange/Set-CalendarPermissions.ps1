<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 02/02/2018
    Organization: Domain, Inc.
    Filename: Set-CalendarPermissions.ps1
    =========================================================
    .DESCRIPTION
        Sets email full access permissions on a users email box.

    .VERSION INFO
        v1.0 - Initial script build
#>

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\FILENAME_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "User, OU, License Status"
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$message"
}

# ----------------------------------------------------------------------------------------------
# Initializations

Write-Host 'Connecting to Office 365 PowerShell' -ForegroundColor Yellow
$O365Cred = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $O365cred -Authentication Basic -AllowRedirection
if($? -eq $true)
{
    Write-Host 'Connection to Office 365 Successful' -ForegroundColor Yellow
}
else 
{
    Write-Host 'Connection to Office 365 Failed. Please try again.' -ForegroundColor Red
    exit
}

Write-Host 'Importing Office 365 PSSession' -ForegroundColor Yellow
Import-PSSession $Session -DisableNameChecking -AllowClobber |Out-Null
if($? -eq $true)
{
    Write-Host 'PSSession Importing has been Completed' -ForegroundColor Yellow
}
else 
{
    Write-Host 'PSSession could not be imported.  Please Try Again.'
    exit
}

# ----------------------------------------------------------------------------------------------
# Functions

function Set-CalendarPermissions ($O365Cred,$cuser,$euser)
{
    $precheck = (Get-MailboxFolderPermission user3:\calendar).user.adrecipient.alias
    if($precheck -contains $euser)
    {
        Write-Host "$euser already has permisisons to this calendar, removing existing permissions in preparation for updated permissions"
        Remove-MailboxFolderPermission -Identity ($cuser + ":\calendar") -User $euser -Confirm:$false
        if($? -eq $false)
        {
            Write-Host "Unable to reset permissions, exiting script."
            exit
        }
    }
    Write-Host "Please select the permission type:
    1. Reviewer
    2. Editor
    3. Publishing Editor
    4. Owner"
    $permission = Read-Host "Enter Selection"
    switch ($permission) {
        "1" 
        { 
            Add-MailboxFolderPermission -Identity ($cuser + ":\calendar") -User $euser -AccessRights reviewer
            if($? -eq $false)
            {
                Write-Host "Unable to set permissions, exiting script."
            exit
            }
            else 
            {
                Write-Host "$euser was given Reviewer permissions successfully"
            }
        }
        "2" 
        { 
            Add-MailboxFolderPermission -Identity ($cuser + ":\calendar") -User $euser -AccessRights editor
            if($? -eq $false)
            {
                Write-Host "Unable to set permissions, exiting script."
            exit
            }
            else 
            {
                Write-Host "$euser was given Editor permissions successfully"
            }
        }
        "3" 
        { 
            Add-MailboxFolderPermission -Identity ($cuser + ":\calendar") -User $euser -AccessRights publishingeditor
            if($? -eq $false)
            {
                Write-Host "Unable to set permissions, exiting script."
            exit
            }
            else 
            {
                Write-Host "$euser was given Publishing Editor permissions successfully"
            } 
        }
        "4" 
        { 
            Add-MailboxFolderPermission -Identity ($cuser + ":\calendar") -User $euser -AccessRights owner
            if($? -eq $false)
            {
                Write-Host "Unable to set permissions, exiting script."
            exit
            }
            else 
            {
                Write-Host "$euser was given Owner permissions successfully"
            } 
        }
        Default 
        { 
            Write-Host "No option selected, exiting script." 
            exit
        }
    }
}

# ----------------------------------------------------------------------------------------------
# Variables

$cuser = Read-Host "Calendar Owner"
$euser = Read-Host "User who needs calendar permissions"

# ----------------------------------------------------------------------------------------------
# Script

Set-CalendarPermissions $O365Cred $cuser $euser

Remove-PSSession $Session