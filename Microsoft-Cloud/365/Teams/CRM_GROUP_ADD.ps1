<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: XX/XX/XXXX
    Organization: Domain, Inc.
    Filename: CRM_GROUP_ADD.ps1
    =========================================================
    .DESCRIPTION
        [ENTER A BRIEF DESCRIPTION OF SCRIPT AND ITS PURPOSE]

    .VERSION INFO
        [ENTER ANY CHANGES MADE HERE]
#>

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\CRM_GROUP_ADD_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "User, Status"
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$message"
}

# ----------------------------------------------------------------------------------------------
# Functions

# ----------------------------------------------------------------------------------------------
# Variables

#get list of usernames from list
$usernames = Get-Content C:\temp\users.txt
$users = @()

# ----------------------------------------------------------------------------------------------
# Script

foreach($username in $usernames)
{
    #remove @example.com from username
    $users += ($username -split "@")[0]
}

$users = $users.trim() -ne ""

foreach($user in $users)
{
    Add-ADGroupMember -Identity "CRM_USERS_SHAREPOINT" -Members $user | Out-Null
    if($? -eq $false)
    {
        Write-host "$user, User not found or already in group"
        Append-Log "$user, User not found or already in group"
    }
    else 
    {
        Write-Host "$user, User added to CRM_USERS_SHAREPOINT group"
        Append-Log "$user, User added to CRM_USERS_SHAREPOINT group"
    }
}


    