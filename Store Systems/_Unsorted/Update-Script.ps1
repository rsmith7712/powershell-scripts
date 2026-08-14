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
    Update-Script.ps1

.SYNOPSIS
  Updated Script
 
.DESCRIPTION
  This script updates the Setup-Ticketing.ps1 script for the Ticketing computers then starts it.
 
.NOTES
  Version:        1.1
  Author:         user26
  Creation Date:  05/14/2018
  Purpose/Change: Added Splunk Logging.

.HISTORY
  Version:        1.0
  Author:         user26 (03/29/2018)

  Purpose/Change: Initial Script Development.

.FUNCTIONALITY
    This script updates the Setup-Ticketing.ps1 script for the Ticketing computers then starts it.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Param(
    $Script:LogFile,
    $Store
)
$ErrorActionPreference = "SilentlyContinue"
$Script:ProductName = "ticketingUpdaterScript"
# ----------------------------------------------------------------------------------------------
# Functions
function Append-Log($message){
    $thetime = Get-Date -Format "HH:mm:ss"
	Add-Content $Script:LogFile "`n$thetime -`n`t$message"
    }
function Log_ToSplunk{
    Param(
    [parameter(Mandatory=$true,
    Position=0)]
    [String]
    $Message,

    [parameter(Mandatory=$false,
    Position=1)]
    [String]
    $Type = "Log",

    [parameter(Mandatory=$false,
    Position=2)]
    [String]
    $Status = "Informational",

    [parameter(Mandatory=$false,
    Position=3)]
    [int]
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
    Invoke-WebRequest -Uri $uri -Method Post -Headers $header -Body $body -TimeoutSec 30 | Out-Null
    }
# ----------------------------------------------------------------------------------------------
# Script
Start-Sleep 5
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"
Log_ToSplunk -Message "Updating Setup Script. Store $Store found." -Type "Log" -Status "Informational"
$CORE = "$($Store)CORE"
$SoftPath = "\\$CORE\Shares\SoftwareDelivery"
If(Test-Path $SoftPath){
    Log_ToSplunk -Message "Local LAN update path found." -Type "Log" -Status "Informational"
    $UpdateLocation = "$($SoftPath)\SITE\Ticketing\Setup-Ticketing.ps1"
}
Else{
    Log_ToSplunk -Message "No Local LAN update path found. Using DFS share." -Type "Log" -Status "Informational"
    $UpdateLocation = "\\SERVER\SHARE\...\Setup-Ticketing.ps1"
}
$ScriptPath = "C:\temp\NextGen\Setup-Ticketing.ps1"
Rename-Item -path $ScriptPath -newName 'Setup-Ticketing.old' -Force
Copy-Item -Path $UpdateLocation -Destination $UpdatePath -Force
if(!($?)){
    Rename-Item -path "C:\temp\NextGen\Setup-Ticketing.old" -newName "Setup-Ticketing.ps1"
    Log_ToSplunk -Message "Something went wrong with the new script download. Restored old script." -Type "Log" -Status "Failure"
    Append-Log "Something went wrong with the new script download. Restored old script."
}
Else{
    Log_ToSplunk -Message "Updated Setup-Ticketing.ps1. Rebooting now." -Type "Log" -Status "Informational"
    Append-Log "Updated Setup-Ticketing.ps1. Rebooting now."
}
Start-Sleep 5
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Restart-Computer -Force