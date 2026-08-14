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
    Reset-DomainAccountCreds.ps1

.SYNOPSIS
    Reset-DomainAccountCreds.ps1

.DESCRIPTION
    Reset-DomainAccountCreds.ps1
    
.EXAMPLE
    Reset-DomainAccountCreds.ps1
 
.NOTES
  Version:        1.0
  Author:         user10
  Creation Date:  11/23/2020
  Purpose/Change: Initial Script Development

.HISTORY

.FUNCTIONALITY
    Reset-DomainAccountCreds.ps1

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
$script:ScriptName = "Reset-DomainAccountCreds.ps1"
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$script:uid =([string](Get-Date -UFormat "%y%m%d") + ".ATM." + [string](Get-Random -Minimum 1000000000 -Maximum 9999999999))
$Script:ProductName = "Reset-DomainAccountCreds"
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
    Param
    (
        [parameter(Mandatory=$true,Position=0)][String]$Message,
        [parameter(Mandatory=$false,Position=1)][String]$Type = "Log",
        [parameter(Mandatory=$false,Position=2)][String]$Status = "Informational",    
        [parameter(Mandatory=$false,Position=3)][int]$ID = $Null
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
            uid = $script:uid
        }
    }
    $body = $body | ConvertTo-Json
    Invoke-WebRequest -Uri $uri -Method Post -Headers $header -Body $body | Out-Null
}#=========================================[End Function]==========================================
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
Function Test-Prereqs
{
    param
    (
        [parameter(Mandatory=$true,Position=0)][string]$param1,
        [parameter(Mandatory=$false,Position=1)][string]$param2
    )

    #<...code...>
}#=======================================[ End Function ]==========================================
Function Generate-StrongPassword ([Parameter(Mandatory=$true)][int]$PasswordLength)
# http://woshub.com/generating-random-password-with-powershell/
{
    Add-Type -AssemblyName System.Web
    $PassComplexCheck = $false
    do
    {
        $newPassword=[System.Web.Security.Membership]::GeneratePassword($PasswordLength,1)
        If ( ($newPassword -cmatch "[A-Z\p{Lu}\s]") `
            -and ($newPassword -cmatch "[a-z\p{Ll}\s]") `
            -and ($newPassword -match "[\d]") `
            -and ($newPassword -match "[^\w]")
        )
        {
            $PassComplexCheck = $True
        }
    } While ($PassComplexCheck -eq $false)
    return $newPassword
}#=======================================[ End Function ]==========================================
Function Set-DomainADPassword($domainAccount,$newPassword)
{
    $ErrorActionPreference = "Stop"
    Try
    {
        Set-ADAccountPassword -Identity $samAccountName -NewPassword $newPassword -Reset
    }
        Catch
        {
           return "[STATUS] : Exception: $($_.Exception.Message)"
        }
    $ErrorActionPreference = "SilentlyContinue"
}#=======================================[ End Function ]==========================================
Function Set-DomainLocalPassword($domainAccount,$newPassword)
{ 
    $ErrorActionPreference = "Stop"
    Try
    {
        Set-LocalUser -Name $samAccountName -Password $newPassword
    }
        Catch
        {
           return "[STATUS] : Exception: $($_.Exception.Message)"
        }
    $ErrorActionPreference = "SilentlyContinue"
}#=======================================[ End Function ]==========================================

#########################################[ SCRIPT STARTS ]#########################################
Set-RunAsAdministrator
Clear-Host
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$stopwatch.Start()
Append-Log -message "[BEGIN]"
#--------------------------------------------------------------------------------------------------

$adAccounts = Get-Content "C:\temp\adAccounts.csv"
$localAccounts = Get-Content "C:\temp\localAccounts.csv"
$pw = Generate-StrongPassword -PasswordLength 15

$adAccounts | 
    ForEach-Object{
        Set-DomainADPassword -domainAccount $adSamAccountName -newPassword $pw
    }
$localAccounts |
    ForEach-Object{
        Set-DomainLocalPassword -domainAccount $localSamAccountName -newPassword $pw
    }

#--------------------------------------------------------------------------------------------------
# Clean up and exit
$elapsed = [math]::Round($stopwatch.Elapsed.TotalMinutes,2)
$stopwatch.Stop()
Append-Log -message "[STATUS] : Script Completion.TTC = $($elapsed) Minutes."
EXIT
#########################################[ SCRIPT ENDS ]###########################################
