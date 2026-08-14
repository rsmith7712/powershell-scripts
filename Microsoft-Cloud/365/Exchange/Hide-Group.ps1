<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 04/13/2018
    Organization: Domain, Inc.
    Filename: Hide-Group.ps1
    =========================================================
    .DESCRIPTION
        Hides a o365 group from the gal.

    .VERSION INFO
        v1 - Initial script build
#>

# ----------------------------------------------------------------------------------------------
# Initializations

$ErrorActionPreference = "SilentlyContinue"

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = get-date -Format yyyy.MM.dd-HH.mm.ss
$Script:Logfile = "C:\temp\Hide-Group_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force | Out-Null
Add-Content $Script:Logfile "User, OU, License Status"
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$message"
}

# ----------------------------------------------------------------------------------------------
# Functions

function connect_exchangeonline($cred)
{
    $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://ps.outlook.com/powershell-liveid" -Credential $cred -Authentication Basic -AllowRedirection
    Import-PSSession $session
    if($? -eq $true)
    {
        return $true
    }
    else 
    {
        return $false
    }
}

function disconnect_exchangeonline
{
    Get-PSSession | Remove-PSSession
}

function check_group($group)
{
    $check = (Get-UnifiedGroup $group).alias
    if($check -ne $null)
    {
        return $true
    }
    else 
    {
        return $false
    }
}

function hide_group($group)
{
    Set-UnifiedGroup $group -HiddenFromAddressListsEnabled $true
    if($? -eq $true)
    {
        return $true
    }
    else
    {
        return $false
    }
}

Function ValidEmailAddress($address)
{
    try
    {
        $x = New-Object System.Net.Mail.MailAddress($address)
        return $true
    }
        catch
    {
        return $false
    }
}

# ----------------------------------------------------------------------------------------------
# Variables

do
{
    #Gets users admin credentials
    $cred = Get-Credential -Message "Please enter your admin credentials. Example: adminaccount@example.com"
    $credcheck = ValidEmailAddress $cred.UserName
}
while ($credcheck -eq $false)

# ----------------------------------------------------------------------------------------------
# Script

Write-Host "Connecting to Exchange Online, please wait."
$exchangestatus = connect_exchangeonline $cred
if($exchangestatus -eq $true)
{
    Write-Host "Succesfully imported session"
    Start-Sleep -Seconds 2
}
elseif($exchangestatus -eq $false)
{
    Write-Host "Something went wrong, attempting connection again."
    $exchangereconnect = connect_exchangeonline $cred
    if($exchangereconnect -eq $true)
    {
        Write-Host "Succesfully imported session"
        Start-Sleep -Seconds 2
    }
    elseif($exchangereconnect -eq $false)
    {
        Write-Host "Unable to connect to exchange online, please try again later"
        exit
    }
}

$continue = $true
do
{
    do
    {
        $group = Read-Host "What group would you like to hide?"
        $groupcheck = check_group $group
        if($groupcheck -eq $false)
        {
            Write-Host "Group does not exist, try again."
        }
    }
    while($groupcheck -eq $false)

    $hidegroup = hide_group $group
    if($hidegroup -eq $true)
    {
        Write-Host "$group group hidden succesfully."
    }
    else 
    {
        Write-Host "Something went wrong while trying to hide $group, please try again."
    }
    
    $continuecheck = Read-Host "Would you like to hide another group? (y/n)"
    if($continuecheck -eq "n")
    {
        $continue = $false
    }
}
until ($continue -eq $false)

disconnect_exchangeonline