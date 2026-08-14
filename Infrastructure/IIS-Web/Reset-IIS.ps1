<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: XX/XX/XXXX
    Organization: Domain, Inc.
    Filename: Reset-IIS.ps1
    =========================================================
    .DESCRIPTION
        [ENTER A BRIEF DESCRIPTION OF SCRIPT AND ITS PURPOSE]

    .VERSION INFO
        [ENTER ANY CHANGES MADE HERE]
#>

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = get-date -Format yyyy.MM.dd-HH.mm.ss
$Script:Logfile = "C:\temp\FILENAME_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "User, OU, License Status"
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$message"
}

# ----------------------------------------------------------------------------------------------
# Functions

function get_credentials()
{
    #Gets users admin credentials
    $cred = Get-Credential

    #below is used to verify authentication
    $username = $cred.username
    $password = $cred.GetNetworkCredential().password

    # Get current domain using logged-on user's credentials
    $CurrentDomain = "LDAP://" + ([ADSI]"").distinguishedName
    $domain = New-Object System.DirectoryServices.DirectoryEntry($CurrentDomain,$UserName,$Password)

    #checks to make sure admin creds are valid
    if ($domain.name -eq $null)
    {
        Clear-Host
        write-host "Authentication failed - please verify your username and password." -ForegroundColor Red
        exit #terminate the script.
    }
    else
    {
        clear-host
        write-host "Credentials Succesfully Verified" -ForegroundColor Yellow
    }
}

function reset_iis($server, $cred)
{
    $session = New-PSSession -ComputerName $server -Credential $cred
    Invoke-Command -Session -ScriptBlock {iisreset.exe /RESTART}
    Remove-PSSession -Session $session
}

# ----------------------------------------------------------------------------------------------
# Variables

$cred = get_credentials

# ----------------------------------------------------------------------------------------------
# Script

Write-Host "Please Enter Name of Server or Type 'q' to quit"
do
{
    $server = Read-Host "Server Name"
    reset_iis $server $cred
}
until($server -eq "q")