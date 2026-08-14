<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: XX/XX/XXXX
    Organization: Domain, Inc.
    Filename: apply-o365licenses.ps1
    =========================================================
    .DESCRIPTION
        [ENTER A BRIEF DESCRIPTION OF SCRIPT AND ITS PURPOSE]

    .VERSION INFO
        [ENTER ANY CHANGES MADE HERE]
#>

# ----------------------------------------------------------------------------------------------
# Initializations

Import-Module -Name MSOnline

Connect-MsolService

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\o365Licensing_$stamp.csv"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "User, License, Status"
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$message"
}

# ----------------------------------------------------------------------------------------------
# Functions

function Apply_ENTERPRISEPACK ($user)
{
    Set-MsolUserLicense -UserPrincipalName $user -RemoveLicenses "domain:ENTERPRISEPACK"
    if($? -eq $true)
    {
        Append-Log "$user, ENTERPRISEPACK, Revoked"
    }
    else 
    {
        Append-Log "$user, ENTERPRISEPACK, Not Revoked"
    }
    start-sleep -Seconds 1
    Set-MsolUserLicense -UserPrincipalName $user -AddLicenses "domain:ENTERPRISEPACK"
    if($? -eq $true)
    {
        Append-Log "$user, ENTERPRISEPACK, Applied"
    }
    else 
    {
        Append-Log "$user, ENTERPRISEPACK, Not Applied"
    }
}

function Apply_POWERAPPS ($user)
{
    Set-MsolUserLicense -UserPrincipalName $user -AddLicenses "domain:POWERAPPS_INDIVIDUAL_USER"
    if($? -eq $true)
    {
        Append-Log "$user, POWERAPPS, Applied"
    }
    else 
    {
        Append-Log "$user, POWERAPPS, Not Applied"
    }
}

# ----------------------------------------------------------------------------------------------
# Variables

$users = (get-msoluser -All | where-object {$_.islicensed -eq "true"}).userprincipalname
#$users = Get-Content C:\temp\users.txt
#$users = $users | ? {$_}
#$users = Read-Host "Enter User Name"

# ----------------------------------------------------------------------------------------------
# Script

foreach($user in $users)
{
    #Apply_ENTERPRISEPACK $user
    Apply_POWERAPPS $user
}