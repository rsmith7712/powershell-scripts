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
    Deploy-DeleteWastedFilesTask.ps1

.SYNOPSIS
  Deploy-DeleteWastedFilesTask.ps1
 
.DESCRIPTION
  Deploy-DeleteWastedFilesTask.ps1 

.EXAMPLE
  Deploy-DeleteWastedFilesTask.ps1

.NOTES
  Version:        1.0
  Author:         user10
  Creation Date:  08/10/2020
  Purpose/Change: Initial Script Development

.HISTORY

.FUNCTIONALITY
    Deploy-DeleteWastedFilesTask.ps1

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

##################[INITIALIZATIONS]###################
[cmdletbinding()]

param
(   [switch]$CsvReport,
    [switch]$Computerlist,
    [switch]$CorpServers,
    [switch]$DomainControllers,
    [switch]$CorpComputers,
    [switch]$RetailServers,
    [switch]$RetailComputers,
    [switch]$Tag,
    [switch]$Reg
)
$script:ProductName = "Remove-WastedFiles"
$script:uid = ([string](Get-Date -UFormat "%y%m%d") + ".ATM." + [string](Get-Random -Minimum 1000000000 -Maximum 9999999999))
$script:script_filepath = $MyInvocation.MyCommand.Path
$script:script_dir = Split-Path -Parent $script:script_filepath
$script:Logfile = "$script:script_dir\logs\$($script:ProductName)_$($script:uid).log"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
#if(Test-Path $script:Logfile){rm $script:Logfile}
$ErrorActionPreference = "SilentlyContinue"

#####################[FUNCTIONS]######################
<#
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
#>
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
Function Deploy-FileRemovalTask
{
    param
    (
        [parameter(Mandatory=$true,Position=0)][string]$computer,
        [parameter(Mandatory=$false,Position=1)][string]$TaskName,
        [parameter(Mandatory=$false,Position=2)][string]$TaskRun,
        [parameter(Mandatory=$false,Position=3)][string]$StartTime,
        [parameter(Mandatory=$false,Position=4)][string]$Schedule
    )
    try
    {    
        SCHTASKS /CREATE /F /s $computer /TN $TaskName /RU "system" /SC $Schedule /ST $StartTime /TR $TaskRun
        $statuscode = $LASTEXITCODE
        if(!($statuscode -eq 0))
        {
            $status = "[ERROR] : Scheduled task could not be created on $computer.";$color = "Red"
        }
            else
            {
                $status = "[SUCCESS] : Scheduled task successfully created on $computer.";$color = "Green"
            }
    }
        catch 
        {
            $status = "[ERROR] : Scheduled task could not be created on $computer. Exception Message: $($_.Exception.Message).";$color = "Red"
        }
        Process-Output -message $status -color $color
        #Log_ToSplunk -Message $status -Type "LOG" -Status $sts
}#===================[End Function]===================
Function Start-FileRemovalTask
{
    param
    (
        [parameter(Mandatory=$true,Position=0)][string]$computer,
        [parameter(Mandatory=$false,Position=1)][string]$TaskName
    )
    try
    {    
        SCHTASKS /RUN /s $computer /TN $TaskName
        $statuscode = $LASTEXITCODE
        if(!($statuscode -eq 0))
        {
            $status = "[ERROR] : Scheduled task could not be started on $computer.";$color = "Red"
        }
            else
            {
                $status = "[SUCCESS] : Scheduled task successfully started on $computer.";$color = "Green"
            }
    }
        catch 
        {
            $status = "[ERROR] : Scheduled task could not be started on $computer. Exception Message: $($_.Exception.Message).";$color = "Red"
        }
        Process-Output -message $status -color $color
        #Log_ToSplunk -Message $status -Type "LOG" -Status $sts
}#===================[End Function]===================
Function Copy-ScriptFile($computer,$source)
{
    $destination = "\\$computer\c$\scripts"
    Try
    {
        Copy-Item -Path "$source\Delete-WastedFiles.ps1" -Destination $destination -Force -PassThru -ErrorAction "Stop"
        Process-Output -message "[SUCCESS] : $computer`: Successfully copied 'Delete-WastedFiles.ps1' from $source to $destination." -color "Green"
    }
        Catch
        {
            Process-Output -message "[ERROR] : $computer`: Online. Exception Message: $($_.Exception.Message)." -color "Red"
        }
        $ErrorActionPreference = "SilentlyContinue"
}#===================[End Function]===================
###################[SCRIPT STARTS]####################
Clear-Host
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$stopwatch.Start()
#Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"
Process-Output -message "Script starting"

#Schtasks parameters
#------------------------------------------------------
[string]$TaskName = "Delete_Wasted_Files"
[string]$TaskRun = "Powershell -executionpolicy bypass -file C:\temp\Delete-WastedFiles.ps1"
[string]$StartTime = "23:59"
[string]$Schedule = "Once"
#------------------------------------------------------
[string]$source = $script:script_dir
$computers = $null
$computers = @()
if ($RetailComputers)
{
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Store Computers Windows 10,OU=Store Computers,DC=DOMAIN,DC=com").name
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Store Jumpstart Computers,OU=Store Computers,DC=DOMAIN,DC=com").name
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Store Computers,OU=Store Computers,DC=DOMAIN,DC=com").name
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Distribution Center Computers,OU=Store Computers,DC=DOMAIN,DC=com").name
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Store DVRs,OU=Store Computers,DC=DOMAIN,DC=com").name
}
if($RetailServers)
{
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Core Servers,OU=Store Servers,DC=DOMAIN,DC=com").name
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=SLC Servers,OU=Store Servers,DC=DOMAIN,DC=com").name
}
if ($Tag)
{
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Store Ticket Computer,OU=Store Computers,DC=DOMAIN,DC=com").name
}
if ($Reg)
{
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Store Register Computers,OU=Store Computers,DC=DOMAIN,DC=com").name
}
if ($CorpComputers)
{
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Corporate Laptops,OU=Corporate Computers,DC=DOMAIN,DC=com").name
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Corporate Desktops,OU=Corporate Computers,DC=DOMAIN,DC=com").name
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Corporate View Desktops,OU=Corporate Computers,DC=DOMAIN,DC=com").name
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Partner Desktops,OU=Partner Computers,DC=DOMAIN,DC=com").name
}
if($CorpServers)
{
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Domain Servers,DC=DOMAIN,DC=com").name
}
if($DomainControllers)
{
     $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Domain Controllers,DC=DOMAIN,DC=com").name
}
if($Computerlist)
{
    $computers += Get-Content "\\SERVER\SHARE\...\cleanthese.txt"
}
if($CsvReport)
{
    $reports = "\\SERVER\SHARE\...\Asset Inventory\infected_detection"
    $csv = (Get-ChildItem $reports -File | Select-Object -Last 1).FullName
    $computerObj = (Import-Csv -Path $csv | Where-Object{$_.Status -match "Wasted" -and $_.Computer -notmatch "-ads-"}).Computer
    $computers = $computerObj | Where-Object {(Get-ADComputer -filter "DNSHostName -like '$_'").DistinguishedName -notmatch "OU=Domain Servers,DC=DOMAIN,DC=com"}
}
#------------------------------------------------------
#$computers = @("srv-ops-fs1")
$computers |
ForEach-Object{
    $computer = $_
    Process-Output "[STATUS] : Checking online status for $computer."
    if(Test-Connection -ComputerName $computer -Count 1 -Quiet)
    {
        Process-Output -message "[STATUS] : $computer`: Confirmed host is online. Continuing operation." -color "Green"
        try
        {
            Process-Output -message "[STATUS] : $computer`: Checking TCP port 135 listening status." -color "Yellow"
            $rpcCheck = (Test-NetConnection -ComputerName "$($computer)" -port 135 -ErrorAction Stop).TcpTestSucceeded
        }
            catch
            {
                "[WARNING] :$($_), The following exception occurred: $($_.Exception.Message)."
            }
        $ErrorActionPreference = "SilentlyContinue"
        if ($rpcCheck)
        {
            Process-Output -message "[STATUS] : $computer`: Confirmed host listening over TCP 135. Continuing operation." -color "Green"
            Deploy-FileRemovalTask -computer $computer -TaskName $TaskName -TaskRun $TaskRun -StartTime $StartTime -Schedule $Schedule
            Copy-ScriptFile -computer $computer -source $source
            Start-FileRemovalTask -computer $computer -TaskName $TaskName
        }
            else
            {
                Process-Output -message "[STATUS] : $computer`: Host is NOT listening over TCP 135. Skipping host." -color "red"
            }
    }
    else 
        {
            Process-Output -message "[ERROR] : $computer : Offline. $computer is unavailable. Cannot continue with $computer." -color "Red"
        }
}
$elapsed = [math]::Round($stopwatch.Elapsed.TotalMinutes,2)
$stopwatch.Stop()
Process-Output -message "[STATUS] : Script Completion.TTC = $($elapsed) Minutes." -color "Green"
Exit
####################[SCRIPT ENDS]#####################