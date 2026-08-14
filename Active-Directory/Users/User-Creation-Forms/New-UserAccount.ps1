<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 10/11/2017
    Organization: Domain, Inc.
    Filename: New-UserAccount.ps1
    =========================================================
    .DESCRIPTION
        Script used to create a new user account. Complete with logging functionality!

    .VERSION INFO
        v1.0 - Intial script build
#>

# ----------------------------------------------------------------------------------------------
#Parameters
Param(
    [Parameter(Mandatory=$true)]
    [string]$firstname,

    [Parameter(Mandatory=$true)]
    [string]$lastname,

    [Parameter(Mandatory=$true)]
    [string]$useralias
)

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\New-UserAccount.ps1_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force | Out-Null
Add-Content $Script:Logfile "Starting Account Creation!"
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$thetime -- $message"
}

# ----------------------------------------------------------------------------------------------
# Initializations

Import-Module -Name ActiveDirectory

Write-Host "Intializing User Account Creation Script" -ForegroundColor Yellow
Write-Host "Please enter your admin credentials. Example: adminaccount@example.com" -ForegroundColor Yellow

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
write-host "Authentication failed - please verify your username and password." -ForegroundColor Red
exit #terminate the script.
}
else
{
write-host "Successfully authenticated with domain $domain.name" -ForegroundColor Yellow
}

#creates and imports a session to the exchange hybrid server.
Write-Host "Creating Session to Hybrid Exchange Server" -ForegroundColor Yellow
$cassession = New-PSSession -ConfigurationName "microsoft.exchange" -ConnectionUri "https://srv-exh-cas1.example.com/powershell" -Credential $cred -Authentication Basic -AllowRedirection
if($? -eq $false)
{
    Write-Host "Could not create session, exiting script" -ForegroundColor Red
    exit
}
else 
{
    Write-Host "Session Created, attempting to import the session." -ForegroundColor Yellow
}
Import-PSSession $cassession -AllowClobber
if($? -eq $false)
{
    Write-Host "Failed to import session, exiting script" -ForegroundColor Red
    exit
}
else 
{
    Write-Host "Session imported succesfully!" -ForegroundColor white -BackgroundColor Blue
}

# ----------------------------------------------------------------------------------------------
# Functions

function New-User ($firstname,$lastname,$useralias,$userpassword,$upn,$name) {
    New-RemoteMailbox -Firstname $firstname -Lastname $lastname -Alias $useralias -Password $userpassword -UserPrincipalName $upn -Name $name -DisplayName $name
}

function Set-OU ($useralias,$cred)
{
    Clear-Host
    Write-Host "Please select an OU to put user account in from the below list, or leave blank to continue." -ForegroundColor Yellow
    Write-Host "
    1.  Administrative Services
    2.  Board Members
    3.  Directors
    4.  Executive Management
    5.  Finance and Accounting
    6.  Human Resources
    7.  Information Systems
    8.  Inventory Management and Logistics
    9.  Marketing
    10. Merchandising
    11. Procurement
    12. Real Estate and Development
    13. Risk Insurance
    14. Sourcing"
    
    $ouselection = Read-Host "Please enter selection"
    Clear-Host

    
    #moves user account to OU based on what switch is selected.  If left blank, nothing happens.
    switch ($ouselection)
    {
        1 {
            Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=administrative services,ou=corporate accounts,dc=domain,dc=com"
            Append-Log "$useralias placed in Administrative Services OU"
        }
        2 {
            Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=board members,ou=corporate accounts,dc=domain,dc=com"
            Append-Log "$useralias placed in Board Members OU"
        }
        3 {
            Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=directors,ou=corporate accounts,dc=domain,dc=com"
            Append-Log "$useralias placed in Directors OU"
        }
        4 {
            Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=executive management,ou=corporate accounts,dc=domain,dc=com"
            Append-Log "$useralias placed in Executive Management OU"
        }
        5 {
            Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=finance and accounting,ou=corporate accounts,dc=domain,dc=com"
            Append-Log "$useralias placed in Finance and Accounting OU"
        }
        6 {
            Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=human resources,ou=corporate accounts,dc=domain,dc=com"
            Append-Log "$useralias placed in Human Resources OU"
        }
        7 {
            Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=information systems,ou=corporate accounts,dc=domain,dc=com"
            Append-Log "$useralias placed in Information Systems OU"
        }
        8 {
            Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=inventory management and logistics,ou=corporate accounts,dc=domain,dc=com"
            Append-Log "$useralias placed in Inventory Management and Logistics OU"
        }
        9 {
            Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=marketing,ou=corporate accounts,dc=domain,dc=com"
            Append-Log "$useralias placed in Marketing OU"
        }
        10 {
            Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=merchandising,ou=corporate accounts,dc=domain,dc=com"
            Append-Log "$useralias placed in Merchandising OU"
        }
        11 {
            Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=procurement,ou=corporate accounts,dc=domain,dc=com"
            Append-Log "$useralias placed in Procurement OU"
        }
        12 {
            Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=real estate and development,ou=corporate accounts,dc=domain,dc=com"
            Append-Log "$useralias placed in Real Estate and Development OU"
        }
        13 {
            Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=risk insurance,ou=corporate accounts,dc=domain,dc=com"
            Append-Log "$useralias placed in Risk Insurance OU"
        }
        14 {
            Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=sourcing,ou=corporate accounts,dc=domain,dc=com"
            Append-Log "$useralias placed in Sourcing OU"
        }
        Default {Append-Log "$useralias was not moved to another OU"}
    }
    Append-Log "$alias"
}

function Set-userdetails ($useralias,$cred) 
{
    $company = "Domain"
    Write-Host "Please select an office location or leave blank to continue" -ForegroundColor Yellow
    Write-Host "
    1. Bellevue
    2. Renton"
    $location = Read-Host "Enter Selection"

    #sets office location based on switch selected. 
    If($location -eq "1")
    {
        $office = "SSC Bellevue"
    }
    elseif($location -eq "2")
    {
        $office = "SSC Renton"
    }

    #sets location variables based on switch selected.
    switch ($location) 
    {
        1 {
            $address = "11400 SE 6th Street Suite 220"
            $City = "Bellevue"
            $state = "WA"
            $zip = "98004"
            $country = "US"
        }
        2 {
            $address = "1100 Oakesdale Ave SW"
            $City = "Renton"
            $state = "WA"
            $zip = "98057"
            $country = "US"
        }
        Default {}
    }
    $title = Read-Host "Please enter users Title"
    $department = Read-Host "Please enter users department"
    
    #Gets manager name with ldap name checking
    do
    {
        if ($count -ge 1)
        {
            Write-Host "Unable to find manager in AD. Try Again" -ForegroundColor Red
        }
        $manager = Read-Host "Please enter the Users Managers account name.  Example: JHurley"
        $managertest = dsquery user -samid $manager
        if ($managertest -eq $null) { $test = $false }
        else { $test = $true }
        $count++
    }
    while ($test -ne $true)

    #checks to see if location info is null or not, then selected which command is to be used.
    if($location -ne $null)
    {
        Set-ADUser -Identity $useralias -Credential $cred -Company $company -StreetAddress $address -City $City -State $state -PostalCode $zip -Country $country -Title $title -Description $title -Department $department -Manager $manager -Office $office 
    }
    else 
    {
        Set-ADUser -Identity $useralias -Credential $cred -Company $company -Title $title -Description $title -Department $department -Manager $manager  
    }
}

function Set-Homepath ($useralias,$cred)
{
    Write-host "Is this a field user or a corporate user? Leave blank to skip" -ForegroundColor Yellow
    Write-Host "
    1. Field
    2. Corp"
    $usertype = Read-Host "Enter Seletion"

    switch($usertype)
    {
        1 {
            $homepath = "\\SERVER\SHARE\...\$useralias"
            $logonscript = "field.cmd"
        }
        2 {
            $homepath = "\\SERVER\SHARE\...\$useralias"
            $logonscript = "corp.cmd"
        }
        Default {}
    }
    if($usertype -ne $null)
    {
        Set-ADUser $useralias -HomeDrive "O:" -HomeDirectory $homepath -ScriptPath $logonscript -Credential $cred
        Append-Log "Logon script and O drive set"
    }
    else {
        Append-Log "Skipped setting logon script and O drive."
    }
}

Function Set-Groups ($useralias,$cred)
{
    $groupconfirmation = Read-Host "Would you like to copy group memberships from another user? (yes or no)"

    if($groupconfirmation -eq "yes")
    {
        do
        {
            if ($count -ge 1)
            {
                Write-Host "Unable to find user in AD. Try Again" -ForegroundColor Red
            }
            $user = Read-Host "Please enter the user whose groups you would like to copy account name.  Example: user3"
            $usertest = dsquery user -samid $user
            if ($usertest -eq $null) { $test = $false }
            else { $test = $true }
            $count++
        }
        while ($test -ne $true)
        $groups = (Get-ADPrincipalGroupMembership $user).SID
        foreach($group in $groups)
        {
            Add-ADGroupMember -Identity $group -Members $useralias -Credential $cred
            Append-Log "user added to $group group."
        }

    }
    else 
    {
        Write-Host "You have opted to skip adding group memberships" -ForegroundColor Red
        Append-Log "Opted to skip adding group memberships"
    }
}

# ----------------------------------------------------------------------------------------------
# Variables

$upn = $useralias + "@example.com"
$name = $firstname + " " + $lastname
$userpassword = ConvertTo-SecureString "<password>" -AsPlainText -Force

# ----------------------------------------------------------------------------------------------
# Script

New-User $firstname $lastname $useralias $userpassword $upn $name
if($? -eq $true)
{
    Write-Host "Account Created!" -ForegroundColor White -BackgroundColor Blue
    Append-Log "User account succesfully created"
    Append-Log "first name set to $firstname"
    Append-Log "Last name set to $lastname"
    Append-Log "Alias set to $useralias"
    Append-Log "User Principal Name set to $upn"
    Append-Log "Display Name set to $name"
}
else 
{
    Write-Host "User account creation failed, exiting script." -ForegroundColor Black -BackgroundColor Red
    Append-Log "User account creationg failed, exiting script."
    exit
}
Write-Host "Script sleeping for 15 seconds to let account replicate to AD. Please Stand By." -ForegroundColor Yellow
Start-Sleep -Seconds 15

#moves the user object to selected OU
Set-OU $useralias $cred

#Sets users Title, department, location, etc...
Set-userdetails $useralias $cred

#sets the users O drive and logon script
Set-Homepath $useralias $cred

Set-Groups $useralias $cred