# LEGAL
<# LICENSE
    MIT License, Copyright 2020 Richard Smith

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
    Set-AzEmailArchive.ps1

.SYNOPSIS
    Set-AzEmailArchive.ps1

.DESCRIPTION
    Set-AzEmailArchive.ps1
    
.EXAMPLE
    Set-AzEmailArchive.ps1
 
.NOTES
    Version:        v1.0
    Author:         user10
    Creation Date:  9/2/2020
    Purpose/Change: Initial script creation

.HISTORY

.FUNCTIONALITY
    Set-AzEmailArchive.ps1

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

###########################################[INITIALIZATIONS ]#######################################
<#
[cmdletbinding()]
param
(
    [string]$param1
    [string]$<ParamName> = $(throw "[ERROR] : -<ParamName> parameter is required.")
    [ValidateSet('item1','item2')]    
)
#>
$script:ScriptName = "Set-AzEmailArchive.ps1"
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$script:uid =([string](Get-Date -UFormat "%y%m%d") + ".ATM." + [string](Get-Random -Minimum 1000000000 -Maximum 9999999999))
$Script:ProductName = "Set-AzEmailArchive"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName).log"
$Script:FixMe = "$script:script_dir\logs\$($Script:ProductName)_FixMe.log"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
if(Test-Path $Script:Logfile){rm $Script:Logfile}
$ErrorActionPreference = "SilentlyContinue"
$ErrorActionPreference = "SilentlyContinue"
##############################################[FUNCTIONS]#############################################
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
}#=======================================[ End Function ]==========================================
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
}#=======================================[ End Function ]==========================================
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
}#=======================================[ End Function ]==========================================
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
}#=======================================[ End Function ]==========================================
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
}#=======================================[ End Function ]==========================================
Function Set-M365Mailbox($alias)
{
    Enable-RemoteMailbox -Identity $alias -Archive
    [string]$state = (Get-RemoteMailbox -Identity $alias).ArchiveState
    $output = "$alias - ArchiveState = $state"
    Write-Host $output -ForegroundColor White -BackgroundColor Blue
    Append-Log $output
}#=======================================[ End Function ]==========================================
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
}#=======================================[ End Function ]==========================================
#########################################[ SCRIPT STARTS ]#########################################
# Begin
#--------------------------------------------------------------------------------------------------
Set-RunAsAdministrator
Clear-Host
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$stopwatch.Start()
Append-Log -message "Script Starting"
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
$userList = Get-Content "\\SERVER\SHARE\...\users.txt"
$userList | foreach{
    [string]$samAccountName = $_.split("@")[0]
    $samAccountName
    Set-M365Mailbox -alias $samAccountName
    }
Remove-Sessions
# --------------------------------------------------------------------------------------------
$elapsed = [math]::Round($stopwatch.Elapsed.TotalMinutes,2)
$stopwatch.Stop()
Process-Output -message "[STATUS] : Script Completion.TTC = $($elapsed) Minutes."
#EXIT    
##########################################[ SCRIPT ENDS ]##########################################
