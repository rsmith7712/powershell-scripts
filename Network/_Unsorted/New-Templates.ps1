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
    New-Templates.ps1

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
$Script:ProductName = "New-ConfigTemplates" #Fill this in. Do not put the "TEAM_" prefix
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

$UFO_NUMBER = Read-Host "Enter UFO_NUMBER"
$sitename = Read-Host "Enter Site Name | NO SPACES"
$serialnode0 = Read-Host "Enter Serial Number of Node0"
$serialnode1 = Read-Host "Enter Serial Number of Node1"
$secondoct = $UFO_NUMBER.Substring(0,2)
$thirdoct = $UFO_NUMBER.substring(2,2)
$thirdoct = $thirdoct.TrimStart("0")

$lookuptable = @{
    'UFO_NUMBER' = "$UFO_NUMBER"
    'SITENAME' = "$sitename"
    'MEMBER0' = "$serialnode0"
    'MEMBER1' = "$serialnode1"
    'x.y' = ($secondoct + '.' + $thirdoct)
}

$MGROrig = "\\SERVER\SHARE\...\Config Templates\Meraki_Configs\MGR_Config_Template.txt"
$MGRNew = ("\\SERVER\SHARE\...\Config Templates\Meraki_Configs\Store_Templates\" + $UFO_NUMBER + "_MGR.txt")

$REGOrig = "\\SERVER\SHARE\...\Config Templates\Meraki_Configs\REG_Config_Template.txt"
$REGNew = ("\\SERVER\SHARE\...\Config Templates\Meraki_Configs\Store_Templates\" + $UFO_NUMBER + "_REG.txt")
    
# Script Starts
#################################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"

Get-Content -Path $MGROrig | ForEach-Object {
  $line = $_

  $lookuptable.GetEnumerator() | ForEach-Object {
      if ($line -match $_.key)
      {
          $line = $line -replace $_.Key, $_.Value
      }
  }
  $line
} | Out-File $MGRNew -Force 
Log_ToSplunk -Message "MGR config template created for $UFO_NUMBER" -Status "success"

Get-Content -Path $REGOrig | ForEach-Object {
  $line = $_

  $lookuptable.GetEnumerator() | ForEach-Object {
      if ($line -match $_.key)
      {
          $line = $line -replace $_.Key, $_.Value
      }
  }
  $line
} | Out-File $REGNew -Force 
Log_ToSplunk -Message "REG config template created for $UFO_NUMBER" -Status "success"

Start-Process -FilePath 'C:\Program Files (x86)\Notepad++\notepad++.exe' -ArgumentList "$MGRNew"
Start-Process -FilePath 'C:\Program Files (x86)\Notepad++\notepad++.exe' -ArgumentList "$REGNew"

# Script Ends
#################################
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Exit