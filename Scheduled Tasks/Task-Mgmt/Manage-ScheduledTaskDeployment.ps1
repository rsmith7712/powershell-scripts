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
    Manage-ScheduledTaskDeployment.ps1

.SYNOPSIS
    Manage-ScheduledTaskDeployment.ps1

.DESCRIPTION
    Manage-ScheduledTaskDeployment.ps1
    
.EXAMPLE
    Manage-ScheduledTaskDeployment.ps1
 
.NOTES
    Version:        v1.0
    Author:         user10
    Creation Date:  7/24/2020
    Purpose/Change: Initial script creation

.HISTORY

.FUNCTIONALITY
    Manage-ScheduledTaskDeployment.ps1

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

###########################################[INITIALIZATIONS ]#######################################
[cmdletbinding()]
param
(
    [Parameter(Mandatory=$false)][ValidateSet("Run","Check","Create","Delete")][String[]]$taskOption,
    [Parameter(Mandatory=$false)][ValidateSet("Check","Copy","Delete")][String[]]$scriptFileOption,
    [Parameter(Mandatory=$false)][ValidateSet("Check","Copy","Delete")][String[]]$moduleFolderOption
)
$script:ScriptName = "Manage-ScheduledTaskDeployment.ps1"
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$script:uid =([string](Get-Date -UFormat "%y%m%d") + ".ATM." + [string](Get-Random -Minimum 1000000000 -Maximum 9999999999))
$Script:ProductName = "Manage-ScheduledTaskDeployment"
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
#<#
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
        [parameter(Mandatory=$false)][string]$splunk = $false,
        [parameter(Mandatory=$false)][string]$splunkType,
        [parameter(Mandatory=$false)][string]$splunkStatus,
        [parameter(Mandatory=$false)][string]$color = "white"
    )
    #<#
    If($splunk)
    {
        Log_ToSplunk -Message $message
    }
    #>
    $ErrorActionPreference = "SilentlyContinue"
    $thetime = Get-Date -Format g
    Write-Host "$thetime`: $message" -ForegroundColor $color
    "$thetime`: $message" | Out-File $script:logfile -Append
}#=========================================[END Function]==========================================
Function Copy-ModuleFolder($computer,$source)
{
    $destination = "\\$computer\c$\scripts"
    if(!(Test-Path "$destination\Modules"))
    {
        robocopy "$($source)\Modules" "$($destination)\Modules" /e /z /w:1 /r:1 /np
        [string]$status = $?
        Process-Output -message "[STATUS] : PS Module copy operation to $computer`: success = $status." 
    }
        else
        {
            Process-Output -message "[STATUS] : Skipping PS Module copy operation to $computer. This folder is already present." -color "Yellow"
        }
    
}#===================[End Function]===================
Function Copy-ScriptFile($computer,$source)
{
    $destination = "\\$computer\c$\scripts"
    Try
    {
        Copy-Item -Path "$source\Backup-site.ps1" -Destination $destination -Force -PassThru -ErrorAction "Stop"
        Process-Output -message "[SUCCESS] : $computer`: Successfully copied 'Backup-site.ps1' from $source to $destination." -color "Green"
    }
        Catch
        {
            Process-Output -message "[ERROR] : $computer`: Online. Exception Message: $($_.Exception.Message)." -color "Red"
        }
        $ErrorActionPreference = "SilentlyContinue"
}#===================[End Function]===================
Function Deploy-GlobalStoreBackupTask
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
        SCHTASKS /CREATE /F /s $computer /TN $TaskName /RU "domain\orgsvc" /RP "<password>" /SC $Schedule /ST $StartTime /TR $TaskRun
        $statuscode = $LASTEXITCODE
        if(!($statuscode -eq 0))
        {
            $status = "[ERROR] : Scheduled Backup task could not be created on $computer.";$color = "Red"
        }
            else
            {
                $status = "[SUCCESS] : Scheduled Backup task successfully created on $computer.";$color = "Green"
            }
    }
        catch 
        {
            $status = "[ERROR] : Scheduled task could not be created on $computer. Exception Message: $($_.Exception.Message).";$color = "Red"
        }
        Process-Output -message $status -color $color
        #Log_ToSplunk -Message $status -Type "LOG" -Status $sts
}#=========================================[End Function]==========================================
#########################################[ SCRIPT STARTS ]#########################################

#Evaluate input parameters
#------------------------------------------------------
if(!($taskOption) -and !($scriptFileOption) -and !($moduleFolderOption))
{
    Process-Output -message "[WARNING] : No action selected for any switch parameters. Please assign an value to at least one switch parameter."
    Exit 1
}
if(!($taskOption)){Process-Output -message "[WARNING] : No action selected for -taskOption switch"}
if(!($scriptFileOption)){Process-Output -message "[WARNING] : No action selected for -scriptFileOption switch"}
if(!($moduleFolderOption)){Process-Output -message "[WARNING] : No action selected for -moduleFolderOption switch"}

# Schtasks parameters
#------------------------------------------------------
[string]$TaskName = "Backup GlobalSTORE to SharePoint"
[string]$TaskRun = "Powershell -executionpolicy bypass -file C:\temp\Backup-site.ps1"
[string]$StartTime = "22:00"
[string]$Schedule = "DAILY"

# File system parameters
#------------------------------------------------------
[string]$source = $script:script_dir

# Evaluate and assign computer objects
#------------------------------------------------------
$computers = Get-ADComputer -Filter * -SearchBase "OU=Core Servers,OU=Store Servers,DC=DOMAIN,DC=com"
$computers | ForEach-Object{
    [string]$computer = $_.Name
    if(Test-Connection -ComputerName $computer -Count 1 -Quiet)
    {
        switch ($taskOption)
        {
            Run
            {
                # Runs existing scheduled task
                schtasks /run /s $computer /tn $TaskName; Process-Output -message "$computer`: '$($Taskname)' running on host: $?."
            }
            Check
            {
                # Checks scheduled task status
                schtasks /query /s $computer /tn $TaskName; Process-Output -message "$computer`: '$($Taskname)' Deployed to host: $?."
            }
            Create
            {
                # Creates new scheduled task
                Deploy-GlobalStoreBackupTask -computer $computer -TaskName $TaskName -TaskRun $TaskRun -StartTime $StartTime -Schedule $Schedule                
            }
            Delete
            {
                # Deletes scheduled task from targeted computers
                schtasks /End /s $computer /tn $TaskName /f; Process-Output -message "$computer`: '$($Taskname)' Ended on host: $?."
                schtasks /Delete /s $computer /tn $TaskName; Process-Output -message "$computer`: '$($Taskname)' Deleted from host: $?."
            }
            Default{}
        }
#------------------------------------------------------        
        switch ($scriptFileOption)
        {
            Check
            {
                # Checks if script file exists.
                if (Test-Path "\\$computer\c$\...\Backup-site.ps1")
                {
                    Process-Output -message  "$computer,Backup-site.ps1 exists." -ForegroundColor Green
                }
                    else
                    {
                        Process-Output -message  "$computer,Backup-site.ps1 does NOT exist." -ForegroundColor Red   
                    }
            }
            Copy
            {
                # Copies script file to targeted computers.
                Copy-ScriptFile -computer $computer -source $source
            }
            Delete
            {
                # Deletes script file from targeted computers'
                if (Test-Path "\\$computer\c$\...\Backup-site.ps1")
                {
                    try 
                    {
                        Remove-Item "\\$computer\c$\...\Backup-site.ps1" -Force -ErrorAction "Stop"
                        Process-Output -message "$computer,Backup-site.ps1 exists." -Color "Green"
                    }
                        catch 
                        {
                            Process-Output -message "[ERROR] : $computer`: Exception Message: $($_.Exception.Message)." -color "Red"
                        }
                }
                    else
                    {
                        Process-Output "$computer,Backup-site.ps1 does NOT exist." -color "Red"
                    }
            }
            Default{}
        }
#------------------------------------------------------        
        switch ($moduleFolderOption)
        {
            Check
            {
                # Checks if module folder exists.
                if (Test-Path "\\$computer\c$\...\Modules")
                {
                    Process-Output -message "$computer,Module folder exists." -ForegroundColor Green
                }
                    else
                    {
                        Process-Output -message "$computer,Module folder does NOT exist." -ForegroundColor Red   
                    }
            }
            Copy
            {
                # Copies PS module to targeted computers.
                Copy-ModuleFolder -computer $computer -source $source
            }
            Delete
            {
                # Deletes PS module from targeted computers'
                if (Test-Path "\\$computer\c$\...\Modules")
                {
                    try 
                    {
                        Remove-Item "\\$computer\c$\...\Modules" -Force -ErrorAction "Stop"
                        Process-Output -message "$computer,Modules folder exists." -Color "Green"
                    }
                        catch 
                        {
                            Process-Output -message "[ERROR] : $computer`: Exception Message: $($_.Exception.Message)." -color "Red"
                        }
                }
                    else
                    {
                        Process-Output "$computer,Modules folder does NOT exist." -color "Red"
                    }
            }
            Default{}
        }
    }
}
##########################################[ SCRIPT ENDS ]##########################################