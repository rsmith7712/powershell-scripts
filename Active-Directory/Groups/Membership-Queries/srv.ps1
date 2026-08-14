<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: XX/XX/XXXX
    Organization: Domain, Inc.
    Filename: SRV_BONUS.ps1
    =========================================================
    .DESCRIPTION
        [ENTER A BRIEF DESCRIPTION OF SCRIPT AND ITS PURPOSE]

    .VERSION INFO
        [ENTER ANY CHANGES MADE HERE]
#>

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = get-date -Format HHmmss.MMddyy
$Script:Logfile = "C:\temp\SRV_BONUS_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "User, OU, License Status"
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$thetime --- $message"
}

# ----------------------------------------------------------------------------------------------
# Functions

function Clear-Group($group){
    $users = Get-ADGroupMember -Identity $group
    Remove-ADGroupMember -Identity $group -Members $users
    Append-Log "DL Cleared"
}

function Add-Member($user,$group){
    Add-ADGroupMember -Identity $group -Members $user
    if($? -eq $false){
        Append-Log "$user, unable to add account"
    }
    else{
        Append-Log "$user, added to group"
    }
}

# ----------------------------------------------------------------------------------------------
# Variables

$group = Get-ADGroup -Filter 'SamAccountName -eq "_SRVBonus"'

$userlist = Get-Content -Path C:\temp\FILENAME.txt
$userlist = $userlist.Trim()

# ----------------------------------------------------------------------------------------------
# Script

Clear-Group $group
foreach($user in $userlist){
    Add-member $user $group
}