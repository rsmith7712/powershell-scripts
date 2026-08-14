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
    CoreServerSync.ps1

.SYNOPSIS
  Syncs the SOFTWAREDELIVERY share to the coreserver
 
.DESCRIPTION
  Script runs locally on core server via scheduled task.  Mirrors specified folders
  
.NOTES
  Version:        1.0
  Author:         user22
  Creation Date:  05/16/2018
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0 
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Script runs locally on core server via scheduled task.  Mirrors specified folders

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Initializations
#################################
$Script:ProductName = "CORESERVERSYNC" #Fill this in. Do not put the "TEAM_" prefix
$ErrorActionPreference = "Inquire" #Maybe change to "SilentlyContinue" for Production.

# Functions
#################################
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\CORESERVERSYNC_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "Starting File Sync"
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$message"
}

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

function copy-software
{
    $sharepath = "D:\SHARES\SOFTWAREDELIVERY\SITE"
    if(!(test-path $sharepath))
    {
        New-Item -Path $sharepath -Force -ItemType Directory
        append-log "$sharepath does not exist yet.  Creating $sharepath"
        Log_ToSplunk -Message "$sharepath does not exist yet.  Creating $sharepath"
    }
    #Copy-Item -Path "\\SERVER\SHARE\...\SITE" -Destination $sharepath -Recurse -PassThru
    & Robocopy.exe "\\SERVER\SHARE\...\Bginfo" "$sharepath\Bginfo" /MIR /log+:$Script:Logfile /NP
    & Robocopy.exe "\\SERVER\SHARE\...\DomainGrade" "$sharepath\DomainGrade" /MIR /log+:$Script:Logfile /NP
    & Robocopy.exe "\\SERVER\SHARE\...\LANDesk" "$sharepath\LANDesk" /MIR /log+:$Script:Logfile /NP
    & Robocopy.exe "\\SERVER\SHARE\...\Ticketing" "$sharepath\Ticketing" /MIR /log+:$Script:Logfile /NP
}
    
# Script Starts
#################################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"

copy-software

# Script Ends
#################################
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Exit