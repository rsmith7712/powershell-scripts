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
    SQLExpressRestart_Modify.ps1

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
  Version:        1.0 (01/01/2001)
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
$Script:ProductName = "SQLExpressRestart_Modify" #Fill this in. Do not put the "TEAM_" prefix
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

$computers = (Get-ADComputer -Filter * -SearchBase "ou=store computers,ou=store computers,dc=domain,dc=com").Name
#$computers = Read-Host "Enter Computer Name"
#$computers = Get-Content "C:\temp\offline.txt"
$offline = New-Item -Path "C:\temp\offline.txt" -ItemType File -Force
$notask = New-Item -Path "C:\temp\notask.txt" -ItemType File -Force
    
# Script Starts
#################################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"

foreach($computer in $computers)
{
    if(Test-Connection -ComputerName $computer -Count 1 -Quiet)
    {
        $taskCheck = schtasks.exe /QUERY /S $computer /TN "sqlmonitor"
        if($taskCheck -eq $null)
        {
            Log_ToSplunk -Message "No task to modify on $computer" -Status "fail"
            Add-Content -Path $notask -Value $computer
        }
        else 
        {
            $task = schtasks.exe /CHANGE /S $computer /TN "SQLMonitor" /RI "5" /RU "domain\domainscheduler" /RP '<password>'
            if($task.substring(0,7) -eq "SUCCESS")
            {
                Log_ToSplunk -Message "Task Succsfully modified on $computer" -Status "success"
            }
        }
    }
    else 
    {
        Log_ToSplunk -Message "$computer - Offline" -Status "fail"
        Add-Content -Path $offline -Value $computer
    }
}

# Script Ends
#################################
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Exit