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
    Deploy-WastedAuditTask.ps1

.SYNOPSIS
    Deploy-WastedAuditTask.ps1

.DESCRIPTION
    Deploy-WastedAuditTask.ps1
    
.EXAMPLE
    Deploy-WastedAuditTask.ps1
 
.NOTES
    Version:        v1.0
    Author:         user10
    Creation Date:  7/12/2020
    Purpose/Change: Initial script creation

.HISTORY

.FUNCTIONALITY
    Deploy-WastedAuditTask.ps1

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
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$script:uid =([string](Get-Date -UFormat "%y%m%d") + ".ATM." + [string](Get-Random -Minimum 1000000000 -Maximum 9999999999))
$Script:ProductName = "Deploy-WastedAuditTask"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName).log"
$Script:FixMe = "$script:script_dir\logs\$($Script:ProductName)_FixMe.log"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
if(Test-Path $Script:Logfile){rm $Script:Logfile}
$ErrorActionPreference = "SilentlyContinue"
###########################################[FUNCTIONS ]############################################
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
}#=========================================[End Function]==========================================
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
Function Process-Output
{
    param
    (
        [parameter(Mandatory=$true)][string]$message,
        [parameter(Mandatory=$false)][string]$splunkLog = $false,
        [parameter(Mandatory=$false)][string]$splunkType,
        [parameter(Mandatory=$false)][string]$splunkStatus,
        [parameter(Mandatory=$false)][string]$color = "white"
    )
    If($splunkLog)
    {
        Log_ToSplunk -Message $message -Type $splunkType -Status $splunkStatus
    }
    $ErrorActionPreference = "SilentlyContinue"
    $thetime = Get-Date -Format g
    Write-Host "$thetime`: $message" -ForegroundColor $color
    "$thetime`: $message" | Out-File $script:logfile -Append
}#=========================================[END Function]==========================================
Function Deploy-Schtask($computer)
{
    $TaskName = "audit-domainWasted"
    SCHTASKS /CREATE /s $Computer /TN $TaskName /SC "ONCE" /RU "SYSTEM" /ST "23:59" /TR "Powershell -executionpolicy bypass -file C:\temp\get-wasted.ps1" /F
        
}#=========================================[END Function]==========================================
Function Copy-Scripts($source,$dest)
{
    $source = $source
    $dest = "\\$computer\C$\...\$($script:ScriptName).ps1"
}#=========================================[END Function]==========================================


    $taskcheck = schtasks.exe /Query /S $Computer /TN $TaskName
    if($taskcheck -eq $null)
    {
        return $false
    }
    else
    {
        return $true
    }

    
$computers = @()
#$computers += (Get-ADComputer -Filter * -SearchBase "ou=store computers,ou=store computers,dc=domain,dc=com" | where-object {$_.name.substring(0,1) -ne "3"}).name
#$computers += (Get-ADComputer -Filter * -SearchBase "ou=store additional computers,ou=store computers,dc=domain,dc=com" | where-object {$_.name.substring(0,1) -ne "3"}).name
#$computers += (Get-ADComputer -Filter * -SearchBase "ou=store jumpstart computers,ou=store computers,dc=domain,dc=com" | where-object {$_.name.substring(0,1) -ne "3"}).name

$script:ScriptName = Get-Wasted
foreach($computer in $computers)
{
    $scriptdest = "\\$computer\C$\...\$($script:ScriptName).ps1"
    $scriptsource = "\\SERVER\SHARE\...\$($script:ScriptName).ps1"
    
    if(Test-Connection -ComputerName $computer -Count 1 -Quiet)
    {
    Copy-Scripts -source $scriptsource -dest $scriptdest

        $task = Create-Task -Computer $computer -TaskName "$($script:ScriptName)" #-XML $xmldest
        if($task -eq $true)
            {
                Append-Log "$computer, Online, Created"
                Write-Host "$computer, Online, Created" -ForegroundColor Green
            }
            else 
                {
                    Append-Log "$computer, Online, Failure"
                    Write-Host "$computer, Online, Failure" -ForegroundColor Red
                }

    }
    else 
        {
            Append-Log "$computer, Offline"
            Write-Host "$computer, Offline" -ForegroundColor Cyan
        }
}

   ##################### [script starts ##################### 


   <#
$computers = @()
$stuff = Import-Csv -Path C:\Temp\Deploy-Cornerstone.csv
foreach($computer in $stuff)
{
    if($computer.status -eq "offline")
    {
        $computers += $computer.computer
    }
    elseif ($computer.Task -eq "") 
    {
        $computers += $computer.computer
    }
}
#>
#$computers = Get-Content C:\temp\computers.txt