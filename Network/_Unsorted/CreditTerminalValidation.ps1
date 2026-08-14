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
    CreditTerminalValidation.ps1

.SYNOPSIS
  Validates that credit terminals are online at specified store site.
 
.DESCRIPTION
  User inputs UFO_NUMBER and function makes a REST API call to the stores Meraki device(s) to see if credit terminals are showing online in vlan 210 ARP table.
  Returns number of online terminals.
  
.NOTES
  Version:        1.0
  Author:         user22
  Creation Date:  05/03/2018
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0 (05/03/2018)
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    User inputs UFO_NUMBER and function makes a REST API call to the stores Meraki device(s) to see if credit terminals are showing online in vlan 210 ARP table.
      Returns number of online terminals.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Initializations
#################################
$Script:ProductName = "CreditTerminalValidation" #Fill this in. Do not put the "TEAM_" prefix
$ErrorActionPreference = "Inquire" #Maybe change to "SilentlyContinue" for Production.

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

function get_terminals
{
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory=$true,
        Position=0)]
        $store
    )

    $baseuri = "https://dashboard.meraki.com/api/v0"
    $header = @{}
    $header.add('Content-Type', 'application/json')
    $header.add('X-Cisco-Meraki-API-Key', '028fa16905a8c75158cceea3633b1ee6b7c72255')

    $orguri = $baseuri + "/organizations/63587/networks"
    $networks = Invoke-RestMethod -Method Get -Uri $orguri -Headers $header
    foreach($network in $networks)
    {
        if(($network.name).substring(0,4) -eq $store)
        {
            $netid = $network.id
        }
    }
    $neturi = $baseuri + "/networks/" + $netid + "/vlans/210"
    
    return ($terminals.count)
}

# Script Starts
#################################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"

$store = Read-Host "Enter UFO_NUMBER"

$terminalcount = get_terminals -store $store

Write-Host "$store has $terminalcount active credit terminals"

# Script Ends
#################################
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Exit