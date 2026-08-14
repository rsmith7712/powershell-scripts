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
    Remove-M365Licenses_TEST.ps1

.SYNOPSIS
    Remove-M365Licenses.ps1

.DESCRIPTION
    Remove-M365Licenses.ps1
    
.EXAMPLE
    Remove-M365Licenses.ps1
 
.NOTES
    Version:        v1.0
    Author:         user10
    Creation Date:  9/2/2020
    Purpose/Change: Initial script creation

.HISTORY

.FUNCTIONALITY
    Remove-M365Licenses.ps1

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
$script:ScriptName = "Remove-M365Licenses.ps1"
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$script:uid =([string](Get-Date -UFormat "%y%m%d") + ".ATM." + [string](Get-Random -Minimum 1000000000 -Maximum 9999999999))
$Script:ProductName = "Remove-M365Licenses"
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
        [parameter(Mandatory=$false,Position=1)][string]$color
    )
    $ErrorActionPreference = "SilentlyContinue"
    $thetime = Get-Date -Format g
    Write-Host "$thetime`: $message" -ForegroundColor $color
    "$thetime`: $message" | Out-File $script:logfile -Append
}#=======================================[ End Function ]==========================================
Function Disable-ADAccount($upn,$enabled)
{
    if($enabled -eq $true)
    {
        Write-Host "$upn is not Disabled. Disabling now..." -ForegroundColor White -BackgroundColor Red
        $disabledStatus = ($adObj | Set-ADUser -UserPrincipalName $upn -Enabled 0 -PassThru).Enabled
        if($disabledStatus -eq $false)
        {
            Set-M365Licenses -upn $upn
        }
    }
        elseif($enabled -eq $false)
        {
            Write-Host "$upn is Disabled" -ForegroundColor White -BackgroundColor DarkGreen
            Set-M365Licenses -upn $upn
        }
        else
        {
           Write-Host "$upn was not found in on-prem AD" -ForegroundColor White -BackgroundColor Blue
           Set-M365Licenses -upn $upn
        }
}#=======================================[ End Function ]==========================================
Function Set-M365Licenses($upn)
{
    Write-Host "Processing $upn" -ForegroundColor White -BackgroundColor DarkGreen
    (Get-MsolUser -userprincipalname $upn).Licenses.AccountSkuId | ForEach-Object{
    [string]$sku = $_
    "$upn,$sku"
    Set-MsolUserLicense -UserPrincipalName $upn -RemoveLicenses $sku
    }
}#=======================================[ End Function ]==========================================
Function Get-M365Licenses($upn,$report)
{
    Write-Host "Processing $upn" -ForegroundColor White -BackgroundColor Blue
    #<#
    (Get-MsolUser -userprincipalname $upn).Licenses.AccountSkuId | ForEach-Object{
        [string]$sku = $_
        "$sku"
        "$upn,$sku" | Out-File $report -Append ascii
    }
    #>
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
Function Connect-MSOL()
{
    $ErrorActionPreference = "Stop"
    Try 
    {
        Import-Module MSOnline
    }
        Catch 
        {
            Write-Host "[ERROR] : The following exception occurred: $($_.Exception.Message). Attempting to install MSOnline Module."
            Install-Module MSOnline -Force
        }
    Try
    {
        Connect-MsolService
        return 0
    }
        Catch
        {
            Write-Host "[ERROR] : The following exception occurred: $($_.Exception.Message)." -ForegroundColor Cyan
            return 1
        }
$ErrorActionPreference = "SilentlyContinue"
}#=======================================[ End Function ]==========================================

#########################################[ SCRIPT STARTS ]#########################################
Clear-Host
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$stopwatch.Start()
Append-Log -message "Script Starting"
$outfile = "$script:script_dir\$MsolLicense.csv"
if(Test-Path $outfile){rm $outfile}
"UserPrincipalName,MsolLicenseSku" | Out-File $outfile -Append ascii

$connectStatus = Connect-MSOL
if($connectStatus -eq 0)
{
    $usernames = Get-ADUser -filter "ObjectClass -like 'user'" -SearchBase "DC=Domain,DC=com"|Where-Object {$_.Enabled -ne $true}
    $usernames.UserPrincipalName|ForEach-Object{
        Get-M365Licenses -upn $_ -report $outfile
        }
}
# --------------------------------------------------------------------------------------------
$elapsed = [math]::Round($stopwatch.Elapsed.TotalMinutes,2)
$stopwatch.Stop()
Append-Log -message "[STATUS] : Script Completion.TTC = $($elapsed) Minutes."
#EXIT    
##########################################[ SCRIPT ENDS ]##########################################