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
    Deploy-WastedAuditTask_Job_2.ps1

.SYNOPSIS
    Deploy-WastedAuditTask_job.ps1

.DESCRIPTION
    Deploy-WastedAuditTask_job.ps1
    
.EXAMPLE
    Deploy-WastedAuditTask_job.ps1
 
.NOTES
    Version:        v1.0
    Author:         user10
    Creation Date:  7/12/2020
    Purpose/Change: Initial script creation

.HISTORY

.FUNCTIONALITY
    Deploy-WastedAuditTask_job.ps1

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
$script:ScriptName = "Get-Wasted"
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
Function Deploy-WastedAudit([string]$computer = $env:COMPUTERNAME)
{
    $ErrorActionPreference = "stop"
    Try
    {
        $scriptBlock = 
        $scriptdest = "\\$computer\C$\...\$($script:ScriptName).ps1";
        $scriptsource = "\\SERVER\SHARE\...\$($script:ScriptName).ps1";
        Copy-Item -Path $scriptsource -Destination $scriptdest;
        $TaskName = "audit-domainWasted";
        SCHTASKS /CREATE /s $Computer /TN $TaskName /SC "ONCE" /RU "SYSTEM" /ST "23:59" /TR "Powershell -executionpolicy bypass -file C:\temp\get-wasted.ps1" /F;
        SCHTASKS /Run /s $Computer /TN $TaskName;
        $status = $?
        Start-Job -Name $computer -ScriptBlock{$using:scriptBlock}
        $status = "[SUCCESS] : PS Job startedt.";$color = "green"
    }
        Catch
        {
            $status = "[WARNING] : Unable to start PS Job. The following exception occurred: $($_.Exception.Message).";$color = "yellow"
        }
    $ErrorActionPreference = "SilentlyContinue"
$runningcount = (Get-Job | Where-Object{$_.State -eq "Running"}).count
$suspendedcount = (Get-Job | Where-Object{$_.State -eq "Suspended"}).count
Write-Host "[JOB STATUS] : Jobs Running: $($runningcount)`nJobs Suspended: $($suspendedcount)"
Get-Job | Where-Object{$_.State -ne "Running"} | Receive-Job
Get-Job | Where-Object{$_.State -eq "Running"} | Wait-Job | Receive-Job
}#=========================================[End Function ]=========================================
#########################################[ SCRIPT STARTS ]#########################################
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$stopwatch.Start()
$ous = @("OU=Corporate Computers,DC=DOMAIN,DC=com",
"OU=Domain Servers,DC=DOMAIN,DC=com",
"OU=Domain Controllers,DC=DOMAIN,DC=com",
"OU=SLC Servers,OU=Store Servers,DC=DOMAIN,DC=com",
"OU=Core Servers,OU=Store Servers,DC=DOMAIN,DC=com")
$ous |
ForEach-Object {
        $ou = $_
        $computeraccounts = Get-ADComputer -Filter "Name -like '*'" -SearchBase $ou
        ForEach($computer in $computeraccounts){
            $name = $computer.Name
            $dn = ($computer.DistinguishedName)
            [string]$ouName = ($dn -split {$_ -eq "," -or $_ -eq "="})[3]
            $test = (Test-Connection $name -Count 1)
            if($test)
            {
                Write-Host "Processing Computer: $name"
                "$name,online,$ou" | Out-File "$script:script_dir\logs\$($ouName)_computers.txt" -Append -Encoding ascii 
                Deploy-WastedAudit -computer $name
            }
                else
                {
                    "$name,offline,$ou" | Out-File "$script:script_dir\logs\$($ouName)_computers.txt" -Append -Encoding ascii 
                }
        }
}