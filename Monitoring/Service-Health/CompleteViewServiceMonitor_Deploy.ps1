# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith

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
    CompleteViewServiceMonitor_Deploy.ps1

.SYNOPSIS
  Deploys SQLExpressRestart script and task
  
.NOTES
  Version:        1.0
  Author:         user22
  Creation Date:  06/12/218
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Deploys SQLExpressRestart script and task

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Initializations
#################################
$Script:ProductName = "CompleteViewServiceMonitor_Deploy" #Fill this in. Do not put the "TEAM_" prefix
$ErrorActionPreference = "SilentlyContinue" #Maybe change to "SilentlyContinue" for Production.

# Functions
#################################
function Log_ToSplunk
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
}

# Variables
#################################

$computers = (Get-ADComputer -Filter * -SearchBase "ou=store dvr's,ou=store computers,dc=domain,dc=com").Name
#$computers = Read-Host "Enter Computer Name"
#$computers = Get-Content "C:\temp\offline.txt"
$offline = New-Item -Path "C:\temp\offline.txt" -ItemType File -Force

# Script Starts
#################################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"

foreach($computer in $computers)
{
    if(Test-Connection -ComputerName $computer -Count 1 -Quiet)
    {
        $xmlpath = "\\SERVER\SHARE\...\CompleteViewServiceMonitor.xml"
        $scriptpath = "\\SERVER\SHARE\...\CompleteViewServiceMonitor.ps1"
        $xmldest = "\\$computer\C$\...\CompleteViewServiceMonitor.xml"
        $scriptdest = "\\$computer\C$\...\CompleteViewServiceMonitor.ps1"
        if(!(Test-Path -Path "\\$computer\C$\scripts"))
        {
            New-Item -Path "\\$computer\C$\scripts" -ItemType Directory -Force
        }
        Copy-Item -Path $xmlpath -Destination $xmldest -Force
        Copy-Item -Path $scriptpath -Destination $scriptdest -Force
        & schtasks.exe /CREATE /S $computer /RU "Administrator" /RP '<password>' /TN "CompleteViewServiceMonitor" /XML $xmldest /F
        $taskCheck = schtasks.exe /QUERY /S $computer /TN "CompleteViewServiceMonitor"
        if($taskCheck -eq $null)
        {
            Log_ToSplunk -Message "Deployment failed on $computer" -Status "fail"
        }
        else
        {
            Log_ToSplunk -Message "Deployment Succesful on $computer" -Status "success"
        }
    }
    else 
    {
        Add-Content -Path $offline -Value $computer
        Log_ToSplunk -Message "$computer offline" -Status "fail"
    }
}

# Script Ends
#################################
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Exit