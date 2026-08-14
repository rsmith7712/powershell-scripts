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
    Restore-RecycledItems.ps1

.SYNOPSIS
  Short & Informational

.NOTES
  Version:        1.0
  Author:         user22
  Creation Date:  01/01/2001
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0 (01/01/2001)
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
$Script:ProductName = "" #Fill this in. Do not put the "TEAM_" prefix
$ErrorActionPreference = "Inquire" #Maybe change to "SilentlyContinue" for Production.
Import-Module Microsoft.Online.SharePoint.PowerShell

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

function Connect-SPO
{

    $adminUPN = Read-Host "Enter your Admin User Principal Name (eg: user3admin@example.com)"
    $cred = get-credential -UserName $adminUPN -Message "Enter Admin Password"

    Connect-SpoService -url "https://domain-admin.sharepoint.com" -Credential $cred
}

function Restore-Items
{
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory=$true,
        Position=0)]
        $SiteURL,

        [parameter(Mandatory=$false,
        Position=1)]
        $DeletedBy,

        [parameter(Mandatory=$false,
        Position=2)]
        $OriginalLocation,

        [parameter(Mandatory=$false,
        Position=3)]
        $DeletedOn
    )
    
    $site = Get-SPSite $SiteURL
    $recycleBin = $site.RecycleBin

    if($DeletedBy -ne $null)
    {
      foreach($item in $recycleBin)
      {
        #if($item.)
      }
    }

    
}
    
# Script Starts
#################################
#Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"

Connect-SPO

# Script Ends
#################################
#Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Exit