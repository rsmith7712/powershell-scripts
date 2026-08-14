<#
    .INFORMATION
    =========================================================
    Created By: user22
    Updated By: user10
    Created On: 10/11/2017
    Organization: Domain, Inc.
    Filename: New-UserAccount.ps1
    =========================================================
    .DESCRIPTION
        Script used to create a new user account. Complete with logging functionality!

    .VERSION INFO
        v1.2 - 11/10/2017 - Fixed bug where user could not be found in 365.
        
    .PREVIOUS VERSION INFO
        v2.0 - 4/19/2018 - Changed script to only accept input values from .CSV file. Added additonal error handling.  Added additional comments. 
        v1.1 - 11/9/2017 - Added functionality to connect to srv-ops-mgmt1 to start an ADSync and then apply a 365 license.
        v1.0 - Intial script build
    
    .REQUIRED
        "C:\Program Files\Microsoft Azure AD Sync\Bin\ADSync\adsync.psd1"
#>

# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
$Script:ProductName = "New-UserAccount"
$ErrorActionPreference = "SilentlyContinue"

# Check .csv file availability and exit if absent
If((Test-Path "C:\temp\SPOUsers.csv") -eq $false){
    Write-Host "No .csv file found. Exiting..."
    EXIT
}

# Logging
# ------------------------------------------------------------------------------------------------
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\New-UserAccount.ps1_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force | Out-Null

Function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$thetime -- $message"
}
function Log_ToSplunk
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
}

# Initializations
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

$Script:ProductName = "New-UserAccount"

Import-Module -Name ActiveDirectory

# Set credentials for account executing script
$username = "svc_UsrMgmt@example.com"
$password = ConvertTo-SecureString -AsPlainText -Force -String "<password>"
$cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $username,$password


# Creates and imports a session to the exchange hybrid server.
# ------------------------------------------------------------------------------------------------

Write-Host "Creating Session on Hybrid Exchange Server" -ForegroundColor Yellow
Append-Log "Creating Session on Hybrid Exchange Server"
$cassession = New-PSSession -ConfigurationName microsoft.exchange -ConnectionUri https://srv-exh-cas1.example.com/powershell -Credential $cred -Authentication Basic -AllowRedirection
if($? -eq $false)
{
    Write-Host "Could not create session, exiting script" -ForegroundColor Red
    Log_ToSplunk -Message "Could not create session, exiting script" -Type "Log" -Status "Informational"
    exit
}
else 
{
    Write-Host "Session Created, attempting to import the session." -ForegroundColor Yellow
    Append-Log "Session Created, attempting to import the session."
}


Import-PSSession $cassession -AllowClobber
if($? -eq $false)
{
    Write-Host "Failed to import session, exiting script" -ForegroundColor Red
    Append-Log "Failed to import session, exiting script"
    exit
}
else 
{
    Write-Host "Session imported succesfully!" -ForegroundColor white -BackgroundColor Blue
    Append-Log "Session imported succesfully!"
}

# Functions
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Function New-User ($firstname,$lastname,$useralias,$userpassword,$upn,$name) {
    New-RemoteMailbox -Firstname $firstname -Lastname $lastname -Alias $useralias -Password $userpassword -UserPrincipalName $upn -Name $name -DisplayName $name
}

# ------------------------------------------------------------------------------------------------
Function Set-OU{
    Get-ADUser $useralias | Move-ADObject -Credential $cred -TargetPath "$OU" -Server "srv"
    Append-Log "$useralias placed in $OUName OU"
}

# ------------------------------------------------------------------------------------------------
Function Set-Userdetails{
    #sets location variables based on switch selected.
    switch ($office)
        {
            "SSC Bellevue" 
            {
                $address = "11400 SE 6th Street Suite 220"
                $City = "Bellevue"
                $state = "WA"
                $zip = "98004"
                $country = "US"
            }

            "SSC Renton" 
            {
                $address = "1100 Oakesdale Ave SW"
                $City = "Renton"
                $state = "WA"
                $zip = "98057"
                $country = "US"
            }

        Default {}
    }

    # Checks to see if location info is null or not, then selected which command is to be used.
    if($office -ne $null)
    {
        Set-ADUser -Identity $useralias -Credential $cred -Company $company -StreetAddress $address -City $City -State $state -PostalCode $zip -Country $country -Title $title -Description $title -Department $department -Office $office -Server "srv"
    }
        else 
        {
            Set-ADUser -Identity $useralias -Credential $cred -Company $company -Title $title -Description $title -Department $department -Server "srv"
        }
}
# ------------------------------------------------------------------------------------------------
Function Set-Homepath{
    switch($usertype)
    {
        "Field User" {
            $homepath = "\\SERVER\SHARE\...\$useralias"
            $logonscript = "field.cmd"
            }
        "Corporate User" {
            $homepath = "\\SERVER\SHARE\...\$useralias"
            $logonscript = "corp.cmd"
            }
        Default {}
    }
    if($usertype -ne $null)
    {
        Set-ADUser $useralias -HomeDrive "O:" -HomeDirectory $homepath -ScriptPath $logonscript -Credential $cred -Server "srv"
        Append-Log "Logon script and O drive set"
    }
    else {
        Append-Log "Skipped setting logon script and O drive."
    }
}

# ------------------------------------------------------------------------------------------------
Function Set-Manager{

# Verifies existance of manager account and sets the attribute
Try
    {
        $manager = (Get-ADUser -LDAPFilter "(UserPrincipalName=$usermanager)" -Credential $cred).SamAccountname
        Set-ADUser -Identity $useralias -Credential $cred -Manager $manager -Server "srv"
    }
        Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
            {
                Append-Log "ERROR: $usermanager alias not found for manager.  Skipping this step."
            }            
}

# ------------------------------------------------------------------------------------------------
Function Set-Groups{

    $srcusr = (Get-ADUser -LDAPFilter "(UserPrincipalName=$copygroupsfrom)").SamAccountname
    $groups = Get-ADPrincipalGroupMembership $srcusr
    foreach($group in $groups)
    {
        Add-ADGroupMember -Identity ($group.SID) -Members $useralias -Credential $cred -Server "srv"
        Append-Log "user added to $group group."
    }
}

# ------------------------------------------------------------------------------------------------
Function Start-Adsync{
    $syncsession = New-PSSession -ComputerName srv-ops-mgmt1 -Credential $cred
    Invoke-Command -Session $syncsession -ScriptBlock {Import-Module "C:\Program Files\Microsoft Azure AD Sync\Bin\ADSync\adsync.psd1"}
    Invoke-Command -Session $syncsession -ScriptBlock {start-adsyncsynccycle -policytype delta}
    Remove-PSSession $syncsession
}

# ------------------------------------------------------------------------------------------------
Function Set-365license{
        Clear-Host
        Write-Host "Attempting to connect to msonline service"
        Append-Log "Attempting to connect to msonline service"
        Connect-MsolService -Credential $cred
        if($? -eq $false)
        {
            Write-Host "Connection failed, please add license to user manually." -ForegroundColor Red
            Append-Log "Connection failed, unable to add office license"
            exit
        }
        else 
        {
            Write-Host "Connection to msonline service established"
            Append-Log "Connection to msonline service established"
        }
    
        #checks to see if user has been imported to o365 yet.
        Get-MsolUser -UserPrincipalName $upn
        if($? -eq $false)
        {
            Write-Host "User not imported into o365 yet, starting another ADSync and then sleeping for 15 seconds."
            Start-Adsync $cred
            Start-Sleep -Seconds 15
        }
    
        #create license options (exclude certain products)
        $license = @()
        #$license += "INTUNE_O365"
        $license += "RMS_S_ENTERPRISE"
        #$license += "TEAMS1"
        #$license += "YAMMER_ENTERPRISE"
        #$license += "EXCHANGE_S_ENTERPRISE"
        $licenseoptions = New-MsolLicenseOptions -AccountSkuId domain:ENTERPRISEPACK -DisabledPlans $license


        Try{
            $ErrorActionPreference = "Stop"
            Set-MsolUser -UserPrincipalName $upn -UsageLocation "$location"
            Set-MsolUserLicense -UserPrincipalName $upn -AddLicenses "domain:ENTERPRISEPACK" -LicenseOptions $licenseoptions
            }

            Catch{
                $ErrorMessage = $_.Exception.Message
                $FailedItem = $_.Exception.ItemName
                Write-Host "ERROR: $ErrorMessage $FailedItem"
                Append-Log "ERROR: $ErrorMessage $FailedItem"
                }

           Finally{
                $ErrorActionPreference = "Continue"
                If((Get-MsolUser -UserPrincipalName $upn).IsLicensed -eq $True){
                    Write-Host "Office license applied for $upn, location set to $location"
                    Append-Log "Office license applied for $upn, location set to $location"
                    }
                Else{
                    Write-Host "ERROR: No Office license applied for $upn"
                    Append-Log "ERROR: No Office license applied for $upn"
                    }
                }

}
# ------------------------------------------------------------------------------------------------
Function Get-MSOnline{
	$check = (Get-Module -ListAvailable -name msonline).Name
	if ($check -eq "MSOnline")
	{
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
}

# -----------------------------------------------------------------------------------------------
Function remove-sessions{
    Get-PSSession | Remove-PSSession
}

# Script
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Log_ToSplunk -Message "Script Starting. Running from Computer: $env:COMPUTERNAME." -Type "Begin" -Status "Informational"

# Import User attributes imported from .CSV file
$csv = Import-Csv "C:\temp\SPOUsers.csv" 

# Assign variables
$csv|ForEach-Object{

# Set OU variable based on values imported from .CSV file
    $OUName = $_.OU
    $OURoot = "ou=corporate accounts,dc=domain,dc=com"
    $OU = "OU="+ $OUName + "," + $OURoot

# Set user account attributes based on values from imported .CSV file
    $firstname = $_.Firstname
    $lastname =  $_.Lastname
    $useralias = $_.UserName
    $upn = $useralias+"@example.com"
    $usertype = $_.UserType
    $title = $_.Title
    $department = $_.Department
    $usermanager = $_.Manager
    $company = "Domain"
    $office = $_.Location
    $location = $_.Country
    $name = $firstname + " " + $lastname
    $userpassword = ConvertTo-SecureString "<password>" -AsPlainText -Force
    $copygroupsfrom = $_.CopyGroupsFrom

# Execute Functions
# ------------------------------------------------------------------------------------------------

# Determines of the MSOnline PowerShell module is installed and installs it as needed
    Get-MSonline

    Import-Module MSOnline

    New-User $firstname $lastname $useralias $userpassword $upn $name
    if($? -eq $true)
    {
        Clear-Host
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
        Clear-Host
        Write-Host "User account creation failed, exiting script." -ForegroundColor Black -BackgroundColor Red
        Append-Log "User account creation failed, exiting script."
        exit
        }

#Starts an adsync so the account is available in o365 to apply a license.
    Start-Adsync $cred
        Start-Sleep -Seconds 30

# Moves the user object to selected OU
    Set-OU $useralias $cred

# Sets users Title, department, location, etc...
    Set-userdetails $useralias $cred

# Populates the manager attribute in AD
    Set-Manager $useralias $cred

# Sets the users O:\ drive and logon script
    Set-Homepath $useralias $cred

# Assigns user to groups (if a source user account is referenced)
    If ($copygroupsfrom -ne "$null"){
        Set-Groups $useralias $cred
    }

# Assigns Office 365 License
    Set-365license $useralias $cred

#Removes any remaining PS remote sessions
    Remove-Sessions

Log_ToSplunk -Message "Script Ending" -Type "End" -Status "Informational"    
}
