# LEGAL
<# LICENSE
    MIT License, Copyright 2001 Richard Smith

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
    RegLogCleanup_Deploy.ps1

.SYNOPSIS
  Short & Informational
 
.DESCRIPTION
  More in depth information.

.EXAMPLE
  If this script can be called from the command line, show examples here
  
.NOTES
  Version:        1.0
  Author:         user22
  Creation Date:  01/01/2001
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    More in depth information.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Initializations
#################################
$ErrorActionPreference = "SilentlyContinue" #Maybe change to "SilentlyContinue" for Production.

# Local Logging
#################################
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\RegLogCleanup_Deploy_remediate.csv"
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

        [parameter(Mandatory=$true,
        Position=2)]
        $XML
    )
    schtasks.exe /create /S $Computer /TN $TaskName /RU "Fujitsu" /RP '<password>' /XML $XML

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

#$computers =@()
#$computers += (Get-ADComputer -Filter * -SearchBase "ou=slc servers,ou=store servers,dc=domain,dc=com").name
#$computers += (Get-ADComputer -Filter * -SearchBase "ou=store register computers,ou=store computers,dc=domain,dc=com").name

#$computers =@()
#$computers += (Get-ADComputer -Filter * -SearchBase "ou=slc servers,ou=store servers,dc=domain,dc=com" | Where-Object {($_.name.substring(0,4) -eq "1125") -or ($_.name.substring(0,4) -eq "1173")}).name
#$computers += (Get-ADComputer -Filter * -SearchBase "ou=store register computers,ou=store computers,dc=domain,dc=com" | Where-Object {($_.name.substring(0,4) -eq "1125") -or ($_.name.substring(0,4) -eq "1173")}).name

$content = Import-Csv -Path C:\temp\RegLogCleanup_Deploy.csv
$computers = @()
foreach($item in $content)
{
    if(($item.Status -eq "offline") -or ($item.Task -eq "failure"))
    {
        $computers += $item.computer
    }
}

#$computers = Read-Host "Enter computer name"

$scriptpath = "\\SERVER\SHARE\...\RegLogCleanup.ps1"
$xmlpath = "\\SERVER\SHARE\...\RegLogCleanup.xml"

# Script Starts
#################################

foreach($computer in $computers)
{
    $scriptdest = "\\$computer\C$\...\RegLogCleanup.ps1"
    $xmldest = "\\$computer\C$\...\RegLogCleanup.xml"
    if(Test-Connection -ComputerName $computer -Count 1 -Quiet)
    {
        Copy-Item -Path $scriptpath -Destination $scriptdest -Force
        Copy-Item -Path $xmlpath -Destination $xmldest -Force
        $task = Create-Task -Computer $computer -TaskName "RegLogCleanup" -XML $xmldest
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