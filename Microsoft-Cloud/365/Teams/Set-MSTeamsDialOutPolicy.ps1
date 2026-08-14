# LEGAL
<# LICENSE
    MIT License, Copyright 2021 Richard Smith

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
    Set-MSTeamsDialOutPolicy.ps1

.SYNOPSIS
 Set-MSTeamsDialOutPolicy.ps1

.DESCRIPTION
 Set-MSTeamsDialOutPolicy.ps1
   
.EXAMPLE
 Set-MSTeamsDialOutPolicy.ps1
 
.NOTES
  Version:        1.0
  Author:         user10
  Creation Date:  2/11/2021
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0
  Author:         user10
  Creation Date:  2/11/2021
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Set-MSTeamsDialOutPolicy.ps1

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
$script:ScriptName = "Set-MSTeamsDialOutPolicy.ps1"
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$script:uid =([string](Get-Date -UFormat "%y%m%d") + ".ATM." + [string](Get-Random -Minimum 1000000000 -Maximum 9999999999))
$Script:ProductName = "Set-MSTeamsDialOutPolicy"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName).log"
$Script:FixMe = "$script:script_dir\logs\$($Script:ProductName)_FixMe.log"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
if(Test-Path $Script:Logfile){rm $Script:Logfile}
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
        [parameter(Mandatory=$false,Position=1)][string]$color = "white"
    )
    $ErrorActionPreference = "SilentlyContinue"
    $thetime = Get-Date -Format g
    Write-Host "$thetime`: $message" -ForegroundColor $color
    "$thetime`: $message" | Out-File $script:logfile -Append
}#=======================================[ End Function ]==========================================
Function Enter-CSOnlineSession ($creds)
{
    Try
    {
        $teamsSession = New-CsOnlineSession -Credential $creds
        Import-PSSession $teamsSession -AllowClobber
    }
        Catch
        {
            Append-Log -message "$($_.Exception.Message)" -color "Cyan"
        }
    Get-PSSession | Enter-PSSession
}#=======================================[ End Function ]==========================================
Function Set-DialoutPolicy($upn,$policy)
{
    # policy can be set to $Null if needing to remove the policy
    # Grant each respective upn the MS Teams dial-out policy as defined below
    Grant-CsDialoutPolicy -identity $upn -PolicyName $policy
    $currentDialoutPolicy = (Get-CsOnlineUser -identity $upn).OnlineDialOutPolicy
    $csUserOutput = "$upn : $currentDialoutPolicy"
    return $csUserOutput
}#=======================================[ End Function ]==========================================
Function Get-DialoutPolicy($upn)
{  
    $currentDialoutPolicy = (Get-CsOnlineUser -identity $upn).OnlineDialOutPolicy
    $usagelocation = (Get-CsOnlineUser -identity $upn).UsageLocation
    $csUserOutput = "$upn - $currentDialoutPolicy `nUsage Location - $usagelocation"
    Append-log -message $($csUserOutput) -color Green
    return $csUserOutput
 }#=======================================[ End Function ]==========================================
Function Close-CSOnlineSession
{
    # Close all established remote PowerShell sessions
    Get-PSSession | Remove-PSSession
}#=======================================[ End Function ]==========================================
#########################################[Script Starts]###########################################
# Import Modules and authentication
#----------------------------------------
Append-Log -message "Script Starts"
Import-Module MicrosoftTeams
Import-Module MSOnline
# Configure remote session credentials
#----------------------------------------
$tpw = ConvertTo-SecureString -String '<password>' -AsPlainText -Force
$tUsr = 'svc_TeamsAutomation@example.com'
$ErrorActionPreference = "Stop"
Try
{
    $script:creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $tUsr, $tPw
    Enter-CSOnlineSession -creds $script:creds    
    Append-Log -message "Successfully entered CSOnlineSession for Teams." -color "Green" 
}
    Catch
    {
        Append-Log -message "$($_.Exception.Message)" -color "Magenta"
    }
    $ErrorActionPreference = "Continue"
    
# Connect to MS Online Services
#----------------------------------------
#Connect-MsolService -Credential $script:creds
## User Account Input
# All ENTERPRISEPACK users
#(Get-MsolUser -all | Where-Object {($_.licenses).accountskuid -match "ENTERPRISEPACK"}).UserPrincipalName |
# Testies123 "user2@example.com","admin2@example.com" 
#$users = Import-Csv "$script:script_dir\Teams Audio Conferencing Pilot.csv"
$users = Get-Content "\\SERVER\SHARE\...\upns.txt"
$users |
ForEach-Object{
    Write-host "Processing $($_)" -ForegroundColor Green
    #Set-MsolUserLicense -UserPrincipalName $($_.userPrincipalName) -AddLicenses "domain:MCOMEETADV" -ErrorAction SilentlyContinue
    Grant-CSDialOutPolicy -Identity $($_) -PolicyName "DialoutCPCDisabledPSTNInternational"
    #(Get-CsOnlineUser -identity $($_)).OnlineDialOutPolicy
}
# Close remote PS sessions and exit
#----------------------------------------
Close-CSOnlineSession
Append-Log -message "Script Ends"
#########################################[Script Ends]#############################################
