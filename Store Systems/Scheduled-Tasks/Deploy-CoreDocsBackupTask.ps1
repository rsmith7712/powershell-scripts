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
    Deploy-CoreDocsBackupTask.ps1

.SYNOPSIS
  Deploy-CoreDocsBackupTask.ps1
 
.DESCRIPTION
  Deploy-CoreDocsBackupTask.ps1 

.EXAMPLE
  
.NOTES
  Version:        1.0
  Author:         user10
  Creation Date:  11/02/2019
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0 (11/02/2019)
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Deploy-CoreDocsBackupTask.ps1

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

##################[INITIALIZATIONS]###################
[cmdletbinding()]
<#
param
(
    [ValidateSet('item1','item2')]
    [string]$param1
)
#>
$script:ProductName = "Deploy-CoreDocsBackupTask"
$script:uid = ([string](Get-Date -UFormat "%y%m%d") + ".ATM." + [string](Get-Random -Minimum 1000000000 -Maximum 9999999999))
$script:script_filepath = $MyInvocation.MyCommand.Path
$script:script_dir = Split-Path -Parent $script:script_filepath
$script:Logfile = "$script:script_dir\logs\$($script:ProductName).log"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
#if(Test-Path $script:Logfile){rm $script:Logfile}
$ErrorActionPreference = "SilentlyContinue"

#####################[FUNCTIONS]######################
<#
Function Verb-Noun
{
    param
    (
        [parameter(Mandatory=$true,Position=0)][string]$parameter1,
        [parameter(Mandatory=$true,Position=1)][string]$parameter2
    )
}#===================[End Function]===================
#>
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
}#===================[End Function]===================
Function Process-Output
{
    param
    (
        [parameter(Mandatory=$true,Position=0)][string]$message,
        [parameter(Mandatory=$false,Position=1)][string]$color
    )
    $ErrorActionPreference = "SilentlyContinue"
    $thetime = Get-Date -Format g
    "$thetime`: $message" | Out-File $script:logfile -Append
    Write-Host "$thetime`: $message" -ForegroundColor $color
}#===================[End Function]===================
Function Deploy-CoreDocsBackupTask($computer)
{
    try
    {    
        SCHTASKS /CREATE /F /s $computer /TN "Backup Core Server Documents" /RU "domain\orgsvc" /RP "<password>" /SC "DAILY" /ST "21:00" /RI "720" /DU "24:00" /TR "Powershell -executionpolicy bypass -file C:\temp\Backup-CoreDocs.ps1"
        $statuscode = $LASTEXITCODE
        if(!($statuscode -eq 0))
        {
            $status = "[ERROR] : Scheduled Backup task could not be created on $computer.";$color = "Red"
            $sts = "FAIL"
        }
            else
            {
                $status = "[SUCCESS] : Scheduled Backup task successfully created on $computer.";$color = "Green"
                $sts = "SUCCESS"
            }
    }
        catch 
        {
            $status = "[ERROR] : Scheduled Backup task could not be created on $computer. Exception Message: $($_.Exception.Message).";$color = "Red"
            $sts = "FAIL"
        }
        Process-Output -message $status -color $color
        Log_ToSplunk -Message $status -Type "LOG" -Status $sts
}#===================[End Function]===================
###################[SCRIPT STARTS]####################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"

$computers = @()
#$computers = @("site","site","site")
$computers += (Get-ADComputer -Filter * -SearchBase "OU=Core Servers,OU=Store Servers,DC=DOMAIN,DC=com" | where-object {$_.name.substring(0,1) -ne "3"}).name
$source = "$script:script_dir\Backup-CoreDocs.ps1"
foreach($computer in $computers){    
    if(Test-Connection -ComputerName $computer -Count 1 -Quiet)
    {
        $destination = "\\$computer\c$\scripts"
        Try
        {
            Copy-Item -Path $source -Destination $destination -Force -PassThru
            $status = "[SUCCESS] : $computer : Online. Successfully copied $source to $destination."
            $sts = "SUCCESS";$color = "Green"
            #Deploy-CoreDocsBackupTask -computer $computer
        }
            Catch
            {
                $status = "[ERROR] : $computer : Online. Exception Message: $($_.Exception.Message)."
                $sts = "FAIL";$color = "Red"
            }
    }
        else 
            {
                $status = "[ERROR] : $computer : Offline. $computer is unavailable. Cannot continue with $computer."
                $sts = "FAIL";$color = "Red"
            }
            Process-Output -message $status -color $color
            Log_ToSplunk -Message $status -Type "LOG" -Status $sts
}
Process-Output -message "Script Ending. $status" -color "Yellow"
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Exit
####################[SCRIPT ENDS]#####################