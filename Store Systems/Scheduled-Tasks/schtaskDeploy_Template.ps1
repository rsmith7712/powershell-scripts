# LEGAL
<# LICENSE
    MIT License, Copyright 2018 Richard Smith

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
    schtaskDeploy_Template.ps1

.SYNOPSIS
  Short & Informational
  
.NOTES
  Version:        1.0
  Author:         user22
  Creation Date:  08/7/2018
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Short & Informational

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Initializations
#################################
$ErrorActionPreference = "SilentlyContinue" #Maybe change to "SilentlyContinue" for Production.
$script:ScriptName = "PUT_SCRIPT_NAME_HERE" # Please make sure script and xml are named the same (aside from file extension).  See below for clarification

# Local Logging
#################################
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\$($script:TaskName).csv"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "Computer,Status,Task"
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$message"
}

# Functions
#################################

function Create-Task
{
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory=$true,
        Position=0)]
        $Computer,

        [parameter(Mandatory=$true,
        Position=1)]
        $TaskName,

        [parameter(Mandatory=$false,
        Position=2)]
        $XML
    )
# With XML config file
    schtasks.exe /create /S $Computer /TN $TaskName /RU "domain\domainscheduler" /RP '<password>' /XML $XML
# Without XML config file    
    # SCHTASKS /create /s "your_remotesystem" /TN "your_taskname" /SC "Once" /RU "domain\orgsvc" /RP "<password>" /ST "Change_Time" /SD "Change_Date" /TR "Powershell.exe -executionpolicy bypass -file C:\temp\your_script.ps1" /f

    $taskcheck = schtasks.exe /Query /S $Computer /TN $TaskName
    if($taskcheck -eq $null)
    {
        return $false
    }
    else
    {
        return $true
    }
}

# Variables
#################################

$computers = @()
$computers += (Get-ADComputer -Filter * -SearchBase "ou=store computers,ou=store computers,dc=domain,dc=com" | where-object {$_.name.substring(0,1) -ne "3"}).name
$computers += (Get-ADComputer -Filter * -SearchBase "ou=store additional computers,ou=store computers,dc=domain,dc=com" | where-object {$_.name.substring(0,1) -ne "3"}).name
$computers += (Get-ADComputer -Filter * -SearchBase "ou=store jumpstart computers,ou=store computers,dc=domain,dc=com" | where-object {$_.name.substring(0,1) -ne "3"}).name

<#
$computers = @()
$stuff = Import-Csv -Path C:\Temp\CornerstoneContentSync_Deploy.csv
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



$scriptpath = "\\SERVER\SHARE\...\$($script:ScriptName).ps1"
$xmlpath = "\\SERVER\SHARE\...\$($script:ScriptName).xml"

# Script Starts
#################################

foreach($computer in $computers)
{
    $scriptdest = "\\$computer\C$\...\$($script:ScriptName).ps1"
    $xmldest = "\\$computer\C$\...\$($script:ScriptName).xml"
    if(Test-Connection -ComputerName $computer -Count 1 -Quiet)
    {
        Copy-Item -Path $scriptpath -Destination $scriptdest -Force
        Copy-Item -Path $xmlpath -Destination $xmldest -Force
        $task = Create-Task -Computer $computer -TaskName "$($script:ScriptName)" -XML $xmldest
        if($task -eq $true)
        {
            Append-Log "$computer, Online, Created"
        }
        else 
        {
            Append-Log "$computer, Online, Failure"
        }
    }
    else 
    {
        Append-Log "$computer, Offline"
    }
}

Exit