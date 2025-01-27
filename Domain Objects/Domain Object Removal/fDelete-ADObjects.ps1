# LEGAL
<# LICENSE
    MIT License, Copyright 2020 Matthew Miller

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
   Delete-ADObjects.ps1

.SYNOPSIS
    - Delete-ADObjects.ps1

.FUNCTIONALITY
    Prompts for Input

.NOTES
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
$script:ScriptName = "Delete-ADObjects.ps1"
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$script:uid =([string](Get-Date -UFormat "%y%m%d") + ".ATM." + [string](Get-Random -Minimum 1000000000 -Maximum 9999999999))
$Script:ProductName = "Delete-ADObjects.ps1"
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
    $product = "crawdads_" + $Script:ProductName
    $uri = "https://hecext.DOMAIN.com:18443/services/collector/event"
    $header = @{}
    $header.add('Content-Type', 'application/json')
    $header.add('Authorization', 'Splunk E6A510A2-844B-4C2F-8E84-1758B36EED5E')
    $body = @{
        sourcetype = 'tvi:ps:log'
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
Function Delete-AdObject([string]$member)
{
    Try
    {
        $adObj = Get-ADObject -filter "Name -like '$($member)'" -Property * | where-object  {$_.ObjectClass -eq "User"}
        if ($null -ne $adObj)
        {
            Remove-ADObject $adObj -Recursive -Confirm:$false
            $output = "STATUS[SUCCESS] : Successfully processed '$($adObj.samAccountName).'";$color = "Green"
        }
            else
            {
                $output = "STATUS[ERROR] : '$($member)' not found in the '$($env:USERDNSDOMAIN)' AD domain.";$color = "Yellow"
            }
    }
        Catch
        {
            $output = "STATUS[EXCEPTION] : The following exception occurred while attempting to process $member`: $($_.Exception.Message).";$color = "Red"
        }
        Append-Log -message $output -color $color
}#=======================================[ End Function ]==========================================

#########################################[ SCRIPT STARTS ]#########################################
#Set-RunAsAdministrator
Clear-Host
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$stopwatch.Start()
Append-Log -message "Script Starting"
#--------------------------------------------------------------------------------------------------
$csv = "c:\scripts\ADUsers.csv"
$adList = Import-Csv $csv
$adList | ForEach-Object{
    Write-Host "Processing $($_.UserName)." -ForegroundColor White -BackgroundColor Blue
    Delete-AdObject -member $($_.UserName)
    }
# --------------------------------------------------------------------------------------------
$elapsed = [math]::Round($stopwatch.Elapsed.TotalMinutes,2)
$stopwatch.Stop()
Process-Output -message "[STATUS] : Script Completion.TTC = $($elapsed) Minutes."
#EXIT    
##########################################[ SCRIPT ENDS ]##########################################    