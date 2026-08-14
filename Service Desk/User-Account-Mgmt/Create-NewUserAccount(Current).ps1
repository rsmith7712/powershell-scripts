# LEGAL
<# LICENSE
    MIT License, Copyright 2019 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the “Software”),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
#>
# GENERAL SCRIPT INFORMATION
<#
.NAME
    Create-NewUserAccount(Current).ps1

.SYNOPSIS
    Create-NewUserAccount.ps1

.DESCRIPTION
    Create-NewUserAccount.ps1
    
.EXAMPLE
    Create-NewUserAccount.ps1
 
.NOTES
    Version:        v1.6
    Author:         user10
    Creation Date:  11/7/2019
    Purpose/Change: Added exception handling and changed the DC name referenced in the script to use 'example.com' rather than an individual DC hostname.

.HISTORY
    v1.5 - 10/11/2019 - Changed srv to SRV-ADS-DC16 throughout the script - msturm
    v1.4 - 4/25/2019 - Removed O Drive mapping, as per user25 Oh's request. Updated by Taizo Curry. 1.3 version moved to the Deprecated folder.
    v1.3 - 3/30/2018 - Added additional error checking for the $cred variable and start-adsync function.
    v1.2 - 11/10/2017 - Fixed bug where user could not be found in 365.
    v1.1 - 11/9/2017 - Added functionality to connect to srv-ops-mgmt1 to start an ADSync and then apply a 365 license.
    v1.0 - Intial script creation. [user22 : 10/11/2017]

.REQUIRED
    "C:\Program Files\Microsoft Azure AD Sync\Bin\ADSync\adsync.psd1"

.FUNCTIONALITY
    Create-NewUserAccount.ps1

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

######################################[INITIALIZATIONS]#######################################
[cmdletbinding()]
<#
param
(
    [ValidateSet('Store','ADQuery')]
    [string]$Target
)
#>
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$Script:ProductName = "Create-NewUserAccount"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName).txt"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
#if(Test-Path $Script:Logfile){rm $Script:Logfile}
$ErrorActionPreference = "SilentlyContinue"

#BANNER
$script:BANNER = "+-+-+-+ +-+-+-+-+ +-+-+-+-+-+-+-+-+
|N|E|W| |U|S|E|R| |C|R|E|A|T|I|O|N|
+-+-+-+ +-+-+-+-+ +-+-+-+-+-+-+-+-+"

#########################################[FUNCTIONS]##########################################
Function Set-RunAsAdministrator()
{
  $CurrentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    if($CurrentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))
  {
       Write-host "Script is running with Administrator privileges!"
  }
  else
    {
        $ElevatedProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell";
        $ElevatedProcess.Arguments = "& '" + $script:MyInvocation.MyCommand.Path + "'"
        $ElevatedProcess.Verb = "runas"
        $ElevatedProcess.WindowStyle = "MINIMIZE"
       [System.Diagnostics.Process]::Start($ElevatedProcess)
       Exit
    }
}#===================[End Function]===================
Function ValidEmailAddress($address) #function to validate that $cred.username is a full email address.
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
}#===================[End Function]===================
Function Append-Log
{
    param
    (
        [parameter(Mandatory=$true,Position=0)][string]$message,
        [parameter(Mandatory=$false,Position=1)][string]$color
    )
    $ErrorActionPreference = "SilentlyContinue"
    $thetime = Get-Date -Format g
    Write-Host "$thetime`: $message" -ForegroundColor $color
    "$thetime`: $message" | Out-File $script:logfile -Append
}#===================[End Function]===================
Function Log_ToSplunk
{
    [CmdletBinding()]
    Param
    (
    [parameter(Mandatory=$true,
    Position=0)]
    $Message,

    [parameter(Mandatory=$false,
    Position=1)]
    $Type = "Log",

    [parameter(Mandatory=$false,
    Position=2)]
    $Status = "Informational",

    [parameter(Mandatory=$false,
    Position=3)]
    $ID = $Null
    )
    $product = "team_" + $Script:ProductName
    $uri = "https://hecext.example.com:18443/services/collector/event"
    $header = @{}
    $header.add('Content-Type', 'application/json')
    $header.add('Authorization', 'Splunk Application-Key-Here')
    $body = @{
        sourcetype = 'domain:ps:log'
        host = $env:COMPUTERNAME
        event = @{
            message = $Message
            user = $env:USERNAME
            product = $Product
            type = $Type
            status = $Status
            id = $ID
        }
    }
    $body = $body | ConvertTo-Json
    Invoke-WebRequest -Uri $uri -Method Post -Headers $header -Body $body | Out-Null
}#===================[End Function]===================
Function Set-ExchangeServerSession($cred)
{
    # Creates and imports a session to the exchange hybrid server.
    Append-Log "[STATUS] : Creating Session on Hybrid Exchange Server" -color "White"
    $ErrorActionPreference = "Stop"
    Try
    {
        $cassession = New-PSSession -ConfigurationName microsoft.exchange -ConnectionUri https://srv-exh-cas1.example.com/powershell -Credential $cred -Authentication Basic -AllowRedirection
        if($? -eq $false)
        {
            Append-Log -message "[ERROR] : Error encountered while attempting to create a new PS session on 'srv-exh-cas1.example.com' Exchange server.`nExiting Script..." -color "Red";Exit
        }
            else 
            {
                Append-Log "[SUCCESS] : PS session created successfully on 'srv-exh-cas1.example.com' Exchange server." -color "Green"
            }
    }
        Catch
        {
            Append-Log -message "[ERROR] : Error encountered while attempting to create a new PS session on 'srv-exh-cas1.example.com' Exchange server.`nException Message: $($_.Exception.Message).`nExiting script..." -color "Red"
            Start-Sleep -Seconds 05
            Exit
        }
    Try
    {
        Import-PSSession $cassession -AllowClobber
        if($? -eq $false)
        {
            Append-Log "[ERROR] : Failed to import CAS Session.`n`nExiting Script..." -color "Red"
        }
            else 
            {
                Append-Log "[SUCCESS] : PS session on 'srv-exh-cas1.example.com' Exchange server successfully imported." -color "Green"
            }
    }
        Catch
        {
            Append-Log -message "[ERROR] : Error encountered while attempting to create a new PS session on 'srv-exh-cas1.example.com'.`nException Message: $($_.Exception.Message).`nExiting script..." -color "Red"
            Start-Sleep -Seconds 05
            Exit
        }
        $ErrorActionPreference = "SilentlyContinue"
}#===================[End Function]===================
Function New-User ($firstname,$lastname,$useralias,$userpassword,$upn,$name)
{
    Clear-Host
    Write-Host $script:BANNER  -ForegroundColor Blue -BackgroundColor White
    Try
    {
        New-RemoteMailbox -Firstname $firstname -Lastname $lastname -Alias $useralias -Password $userpassword -UserPrincipalName $upn -Name $name -DisplayName $name
        Append-log -message "[SUCCESS] : User AD account creation was successful." -color "Green"
    }
        Catch
        {
            Append-Log "[ERROR] : The following exception was encountered: $($_.Exception.Message)." -color "Red"
        }    
}#===================[End Function]===================
Function Set-ADOU($useralias,$cred,$OUName,$OU)
{
    Try
    {
        Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "$OU" -Server "example.com" #"srv"
        Append-Log "[SUCCESS] : $useralias placed in $OUName OU" -color "Green"
    }
        Catch
        {
            Append-Log "[ERROR] : The following exception was encountered: $($_.Exception.Message)." -color "Red"
        }
}#===================[End Function]===================
Function Set-Userdetails($useralias,$cred)
{
    Clear-Host
    Write-Host $script:BANNER  -ForegroundColor Blue -BackgroundColor White
    $company = "Domain"
    Write-Host "Please select an office location or leave blank to continue" -ForegroundColor Yellow
    Write-Host "
    1. Bellevue
    2. Renton"
    $o = Read-Host "Enter Selection"
    switch ($o)
    {
        "1"
            {
                $office = "SSC - Bellevue"
                $address = "11400 SE 6th Street Suite 220"
                $City = "Bellevue"
                $state = "WA"
                $zip = "98004"
                $country = "US"
            }
        "2"
            {
                $office = "SSC - Renton"
                $address = "1100 Oakesdale Ave SW"
                $City = "Renton"
                $state = "WA"
                $zip = "98057"
                $country = "US"
            }
        Default {}
    }#--------------------[End Switch]--------------------
    $title = Read-Host "Please enter users Title"
    $department = Read-Host "Please enter users department"
    if($null -ne $office)
    {
        Try
        {
            Set-ADUser -Identity $useralias -Credential $cred -Company $company -StreetAddress $address -City $City -State $state -PostalCode $zip -Country $country -Title $title -Description $title -Department $department -Office $office -Server "example.com" #"srv"
            Append-Log "[SUCCESS] : Successfully configured 'location-based' attributes to the $($useralias) AD user account." -color "Green"
        }
            Catch 
            {
                Append-Log "[ERROR] : The following exception was encountered: $($_.Exception.Message)." -color "Red"
            }
    }#--------------------[End If]--------------------
        else 
        {
            Try
            {
                Set-ADUser -Identity $useralias -Credential $cred -Company $company -Title $title -Description $title -Department $department -Server "example.com"
                Append-Log "[SUCCESS] : Successfully added remaining user attributes to the $($useralias) AD user account." -color "Green"
            }
                Catch 
                {
                    Append-Log "[ERROR] : The following exception was encountered: $($_.Exception.Message)." -color "Red"
                }
        }#--------------------[End Else]--------------------
}#===================[End Function]===================
Function Set-LogonScript($useralias,$cred) #CURRENTLY NOT BEING USED
{
    Write-Host "Please select an office location or leave blank to continue" -ForegroundColor Yellow
    Write-Host "
    1. Field User
    2. Corporate User"
    $usertype = Read-Host "Enter Selection"
    switch($usertype)
    {
        "1" {
            #$homepath = "\\SERVER\SHARE\...\$useralias"
            $logonscript = "field.cmd"
            }
        "2" {
            #$homepath = "\\SERVER\SHARE\...\$useralias"
            $logonscript = "corp.cmd"
            }
        Default {}
    }
    if($null -ne $usertype)
    {
        Set-ADUser $useralias -ScriptPath $logonscript -Credential $cred -Server "example.com" #"srv"
        Append-Log "[SUCCESS] : Logon script successfully assigned for DOMAIN\$useralias." -color "Green"
    }
        else 
        {
            Append-Log "[ERROR] : Unable to assign logon script attribute for DOMAIN\$useralias." -color "Red"
        }
}#===================[End Function]===================
Function Set-Manager($cred,$useralias,$usermanager)
{
    $mgrupn = $usermanager + "@example.com"
    Try
    {
        $manager = (Get-ADUser -LDAPFilter "(UserPrincipalName=$mgrupn)" -Credential $cred).SamAccountname
        Set-ADUser -Identity $useralias -Credential $cred -Manager $manager -Server "example.com" #"srv"
        Append-Log "[SUCCESS] : Successfully assigned Manager attribute for DOMAIN\$useralias." -color "Green"
    }
        Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
        {
            Append-Log "[WARNING] : $mgrupn alias not found for manager.  Skipping this step." -color "Yellow"
        }
        Catch
        {
            Append-Log "[ERROR] : Exception encountered when attempting to configure the 'Manager' attribute. $($_.Exception.Message)." -color "Red"
        }          
}#===================[End Function]===================
Function Set-Groups($cred,$useralias,$copygroupsfrom)
{
    $grpsupn = $copygroupsfrom + "@example.com"
    $srcusr = (Get-ADUser -LDAPFilter "(UserPrincipalName=$grpsupn)").SamAccountname
    $groups = Get-ADPrincipalGroupMembership $srcusr
    foreach($group in $groups)  {
                                    Try 
                                    {
                                        Add-ADGroupMember -Identity ($group.SID) -Members $useralias -Credential $cred
                                        Append-Log "[SUCCESS] : User added to $group group." -color "Green"
                                    }
                                        Catch 
                                        {
                                            Append-Log "[ERROR] : The following exception was encountered: $($_.Exception.Message)." -color "Red"
                                        }                                    
                                }
}#===================[End Function]===================
Function Start-Adsync($cred)
{
    Append-Log "[STATUS] : Creating Session on Hybrid Exchange Server" -color "White"
    Try
    {
        $syncsession = New-PSSession -ComputerName "srv-ops-mgmt1" -Credential $cred
        Invoke-Command -Session $syncsession -ScriptBlock {Import-Module "C:\Program Files\Microsoft Azure AD Sync\Bin\ADSync\adsync.psd1"}
        Invoke-Command -Session $syncsession -ScriptBlock {start-adsyncsynccycle -policytype delta}
        Remove-PSSession $syncsession
    }
        Catch 
        {
            Append-Log "[ERROR] : The following exception was encountered: $($_.Exception.Message)." -color "Red"
        }    
}#===================[End Function]===================
Function Set-365license($cred,$upn)
{
    Clear-Host
    Write-Host $script:BANNER  -ForegroundColor Blue -BackgroundColor White
    Append-Log "[STATUS] : Attempting to connect to msonline service." -color "White"
    Connect-MsolService -Credential $cred
    if($? -eq $false)
    {
        Append-Log "[ERROR] : Connection failed, unable to add office license. Exiting Script." -color "Red"
        Start-Sleep -Seconds 05
        Exit
    }
        else 
        {
            Append-Log "[SUCCESS] : Connection to msonline service established" -color "Green"
        }
    #checks to see if user has been imported to o365 yet.
    Try
    {
        $o365usercheck = Get-MsolUser -UserPrincipalName $upn
        $synccount = 0
        if(($o365usercheck.DisplayName -eq $null) -or ($o365usercheck.DisplayName -eq ""))
        {
            do
            {
                if($synccount -gt 5)
                {    
                    Append-Log -message "[WARNING] : Delta Sync is not working.  Please assign a license to this user manually. Exiting Script..." -color "Yellow"
                    Start-Sleep -Seconds 05
                    Exit
                }
                $o365usercheck = Get-MsolUser -UserPrincipalName $upn
                if($o365usercheck -eq $null)
                {
                    Append-Log -message "[WARNING] : User not imported into o365 yet, starting another ADSync and then sleeping for 15 seconds." -color "Yellow"
                    #Start-Adsync $cred
                    Start-Countdown -sec 15 -Message "***** Please Stand-by While AD Synchronization Completes.  [Sleeping 15 Seconds] *****"
                    $synccount ++
                }
            }
            until($o365usercheck -eq $true)
        }
    }
        Catch 
        {
            Append-Log "[ERROR] : The following exception was encountered: $($_.Exception.Message)." -color "Red"
        }
    ###################################################
    #create license options (exclude certain products)
    $license = @()
    #$license += "INTUNE_O365"
    $license += "RMS_S_ENTERPRISE"
    #$license += "TEAMS1"
    #$license += "YAMMER_ENTERPRISE"
    #$license += "EXCHANGE_S_ENTERPRISE"
    $licenseoptions = New-MsolLicenseOptions -AccountSkuId domain:ENTERPRISEPACK -DisabledPlans $license
    ###################################################
    Write-Host "Is the user located in the US, CA or AU?" -ForegroundColor Yellow
    Write-Host "
    1. US
    2. CA
    3. AU"
    $location = Read-Host "Enter Selection"

    switch ($location) 
    {
        1 {$UsageLocation = "US"}
        2 {$UsageLocation = "CA"}
        3 {$UsageLocation = "AU"}
    }
    Try
    {
        $ErrorActionPreference = "Stop"
        Set-MsolUser -UserPrincipalName $upn -UsageLocation "$UsageLocation"
        $msoluserstatus = $?
        Append-Log -message "[STATUS] : Set-MsolUser 'Success' status = $msoluserstatus" -color "White"
        Set-MsolUserLicense -UserPrincipalName $upn -AddLicenses "domain:ENTERPRISEPACK" -LicenseOptions $licenseoptions
        $msoluserlicensestatus = $?
        Append-Log -message "[STATUS] : Set-MsolUserLicense 'Success' status = $msoluserlicensestatus" -color "White"
    }
        Catch 
        {
            Append-Log "[ERROR] : Unable to apply MSOL license(s) for $upn.`nThe following exception was encountered: $($_.Exception.Message)." -color "Red"
        }
    Finally
    {
        if((Get-MsolUser -UserPrincipalName $upn).IsLicensed -eq $True)
        {
            Append-Log "[SUCCESS] : Office license applied for $upn, location set to $location" -color "Green"
        }
                else
                {
                    Append-Log "[WARNING] : No Office license applied for $upn." -color "Yellow"
                }
        $ErrorActionPreference = "Continue"
    }
}#===================[End Function]===================
Function Get-MSOnline()
{
    Clear-Host
    Write-Host $script:BANNER  -ForegroundColor Blue -BackgroundColor White
	$check = (Get-Module -ListAvailable -name msonline).Name
	if ($check -eq "MSOnline")
	{
        Append-Log -message "[STATUS] : Executing 'Get-MSOnline' to see if it is installed..." -color "White"
	}
        else
        {
            if (!(test-path C:\software))
            {
                New-Item -Path C:\Software -ItemType Directory
                Copy-Item -path "\\SERVER\SHARE\...\Desktop Software\Powershell\msonline\msoidcli_64.msi" -Destination C:\Software\msoidcli_64.msi -Force
                Copy-Item -path "\\SERVER\SHARE\...\Desktop Software\Powershell\msonline\AdministrationConfig-en.msi" -destination C:\Software\Administrationconfig-en.msi -Force
                Start-Process msiexec.exe -ArgumentList "/i C:\software\msoidcli_64.msi /qn" -wait
                Start-Process msiexec.exe -ArgumentList "/i C:\software\Administrationconfig-en.msi /qn" -wait
            }
                else
                {
                    Copy-Item -path "\\SERVER\SHARE\...\Desktop Software\Powershell\msonline\msoidcli_64.msi" -Destination C:\Software\msoidcli_64.msi -Force
                    Copy-Item -path "\\SERVER\SHARE\...\Desktop Software\Powershell\msonline\AdministrationConfig-en.msi" -destination C:\Software\Administrationconfig-en.msi -Force
                    Start-Process msiexec.exe -ArgumentList "/i C:\software\msoidcli_64.msi /qn" -wait
                    Start-Process msiexec.exe -ArgumentList "/i C:\software\Administrationconfig-en.msi /qn" -wait
                }
        }
}#===================[End Function]===================
Function Set-OU ($useralias,$cred)
{
    Clear-Host
    Append-Log -message "Please select and OU to put user account in from the below list, or leave blank to continue." -color White
    Write-Host "
    1.  Administrative Services
    2.  Board Members
    3.  Contractor ('c-' accounts)
    4.  Directors
    5.  Executive Management
    6.  Finance and Accounting
    7.  Human Resources
    8.  Information Systems
    9.  Inventory Management and Logistics
    10. Marketing
    11. Merchandising
    12. Procurement
    13. Real Estate and Development
    14. Risk Insurance
    15. Sourcing"
    $ouselection = Read-Host "Please enter selection"
    switch ($ouselection)
    {
        1 {Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=administrative services,ou=corporate accounts,dc=domain,dc=com" -Server "example.com"}
        2 {Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=board members,ou=corporate accounts,dc=domain,dc=com" -Server "example.com"}
        3 {Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "OU=External Accounts,OU=Domain Services,DC=DOMAIN,DC=com" -Server "example.com"}
        4 {Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=directors,ou=corporate accounts,dc=domain,dc=com" -Server "example.com"}
        5 {Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=executive management,ou=corporate accounts,dc=domain,dc=com" -Server "example.com"}
        6 {Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=finance and accounting,ou=corporate accounts,dc=domain,dc=com" -Server "example.com"}
        7 {Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=human resources,ou=corporate accounts,dc=domain,dc=com" -Server "example.com"}
        8 {Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=information systems,ou=corporate accounts,dc=domain,dc=com" -Server "example.com"}
        9 {Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=inventory management and logistics,ou=corporate accounts,dc=domain,dc=com" -Server "example.com"}
        10 {Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=marketing,ou=corporate accounts,dc=domain,dc=com" -Server "example.com"}
        11 {Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=merchandising,ou=corporate accounts,dc=domain,dc=com" -Server "example.com"}
        12 {Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=procurement,ou=corporate accounts,dc=domain,dc=com" -Server "example.com"}
        13 {Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=real estate and development,ou=corporate accounts,dc=domain,dc=com" -Server "example.com"}
        14 {Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=risk insurance,ou=corporate accounts,dc=domain,dc=com" -Server "example.com"}
        15 {Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "ou=sourcing,ou=corporate accounts,dc=domain,dc=com" -Server "example.com"}
        Default {Append-Log "$useralias was not moved to another OU"}
    }
}#===================[End Function]===================
Function Start-Countdown() 
{ #https://community.spiceworks.com/scripts/show/1712-start-countdown - Martin Pugh   
    Param(
        [Int32]$sec = 60,
        [string]$Message = "Pausing for $($sec) seconds..."
    )
    ForEach ($Count in (1..$Sec))
    {   Write-Progress -Id 1 -Activity $Message -Status "Waiting for $Sec seconds, $($Sec- $Count) left" -PercentComplete (($Count / $sec) * 100)
        Start-Sleep -Seconds 1
    }
    Write-Progress -Id 1 -Activity $Message -Status "Completed" -PercentComplete 100 -Completed
}#===================[End Function]===================
Function Remove-Sessions()
{
    Try
    {
        Get-PSSession | Remove-PSSession
        Append-Log "[SUCCESS] : PS session connection to msonline service successfully terminated." -color "Green"
    }
        Catch
        {
            Append-Log "[ERROR] : Unable to terminate the PSSession to the Exchange server. The following exception was encountered: $($_.Exception.Message)." -color "Red"
        }
}#===================[End Function]===================

#######################################[SCRIPT STARTS]########################################
Log_ToSplunk -Message "Script Starting. Running from Computer: $env:COMPUTERNAME." -Type "Begin" -Status "Informational"
Clear-Host
Write-Host $script:BANNER  -ForegroundColor Blue -BackgroundColor White
Import-Module -Name ActiveDirectory
Append-Log -message "[STATUS] : Intializing User Account Creation Script" -color "White"
Append-Log -message "Please enter your admin credentials. Example: adminaccount@example.com" -color "Yellow"
do
{
    # Obtain user credentials
    $cred = Get-Credential -Message "Enter your administrative user credentials (e.g., UsernameAdmin@example.com)" -UserName "$($env:USERNAME)@example.com"
    $credcheck = ValidEmailAddress $cred.UserName
}
while ($credcheck -eq $false)
# --------------------------------------------------------------------------------------------
# Authentication verification
$username = $cred.username
$password = $cred.GetNetworkCredential().password
# --------------------------------------------------------------------------------------------
# Get current domain using logged-on user's credentials
$CurrentDomain = "LDAP://" + ([ADSI]"").distinguishedName
$domain = New-Object System.DirectoryServices.DirectoryEntry($CurrentDomain,$UserName,$Password)
# --------------------------------------------------------------------------------------------
#checks to make sure admin creds are valid
if ($domain.name -eq $null)
{
    Append-Log -message "[WARNING] : Authentication failed - please verify your username and password." -color "Yellow"
    Exit
}
    else
    {
        Append-Log -message "[SUCCESS] : $domain.name authentication succeeded." -color "Green"
    }
$cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $username ,$password
Set-ExchangeServerSession -cred $cred
# --------------------------------------------------------------------------------------------
# Set user account attributes based on values entered manually.
    Clear-Host
    Write-Host $script:BANNER  -ForegroundColor Blue -BackgroundColor White
    Write-Host "";Write-Host "";Write-Host ""
    $firstname = Read-Host "Please Enter The User's Firstname"
    $lastname =  Read-Host "Please Enter The User's Lastname"
    $useralias = Read-Host "Please Enter The User's Alias (SamAccountName)"
    $upn = $useralias+"@example.com"
    $name = $firstname + " " + $lastname
    $mgr = Read-Host "Please Enter The User's Manager Alias"
    $grps = Read-Host "Please Enter The Alias of a User whose AD Group Membership should be duplicated for DOMAIN\$useralias"
    $userpassword = ConvertTo-SecureString "<password>" -AsPlainText -Force
# --------------------------------------------------------------------------------------------       
# Determines if the MSOnline PowerShell module is installed and installs it as needed
    Get-MSonline
    Import-Module MSOnline
    New-User -firstname $firstname -lastname $lastname -useralias $useralias -userpassword $userpassword -upn $upn -name $name
    if($? -eq $true)
    {
        Clear-Host
        Append-log "Account Created!" -color "Magenta"
        Append-Log "User account succesfully created" -color "Magenta"
        Append-Log "First name set to $firstname" -color "Magenta"
        Append-Log "Last name set to $lastname" -color "Magenta"
        Append-Log "Alias set to $useralias" -color "Magenta"
        Append-Log "User Principal Name set to $upn" -color "Magenta"
        Append-Log "Display Name set to $name" -color "Magenta"
    }
        else 
            {
                Clear-Host
                Append-Log "[ERROR] : User account creation failed, exiting script." -color "Red"
                Exit
            }
# --------------------------------------------------------------------------------------------
    Append-Log -message "##### Moves the user object to selected OU. #####" -color "Cyan"
        Set-OU -useralias $useralias -cred $cred
    Append-Log -message "##### Sets users Title, department, location, etc... #####" -color "Cyan"
        Set-UserDetails -useralias $useralias -cred $cred
    Append-Log -message "##### Populates the manager attribute in AD. #####" -color "Cyan"
        Set-Manager -useralias $useralias -cred $cred -usermanager $mgr
    Append-Log -message "##### Sets the users logon script. #####" -color "Cyan"
        Set-LogonScript -useralias $useralias -cred $cred
    Append-Log -message "##### Assigns user to groups (if a source user account is referenced). #####" -color "Cyan"
        If ($null -ne $grps){Set-Groups -useralias $useralias -cred $cred -copygroupsfrom $grps}
    Append-Log -message "##### Initiating an ADSync (2/2), so the account is available in o365 to apply a license. #####" -color "Cyan"
        CLS
        Write-Host ""
        Write-Host "***** Please Stand-by While AD Synchronization Completes.  [Sleeping 60 Seconds] *****" -ForegroundColor Blue -BackgroundColor White
        Start-Adsync -cred $cred; Start-Countdown -sec 60 -Message "***** Please Stand-by While AD Synchronization Completes.  [Sleeping 60 Seconds] *****"
    Append-Log -message "##### Assigns Office 365 License. #####" -color "Cyan"
        Set-365license -upn $upn -cred $cred
    Append-Log -message "##### Removes any remaining PS remote sessions. #####" -color "Cyan"
# --------------------------------------------------------------------------------------------
    Clear-Host
    Write-Host "#################################[ Active Directory Services ]################################" -ForegroundColor Blue -BackgroundColor White
    Get-ADUser $useralias -Properties * | Select-Object *
    Write-Host "####################################[ MS Online Services ]####################################" -ForegroundColor Blue -BackgroundColor White
    Get-MsolUser -UserPrincipalName $upn
    Write-Host "##############################################################################################" -ForegroundColor Blue -BackgroundColor White
    Remove-Sessions
    Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
    Exit
#########################################[SCRIPT END]#########################################

