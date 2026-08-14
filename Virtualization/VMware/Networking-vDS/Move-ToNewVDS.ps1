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
    Move_ToNewVDS.ps1

.SYNOPSIS
  Moves all VMs on a specified DVS to another specified DVS
 
.DESCRIPTION
  More in depth information.
  
.NOTES
  Version:        1.0
  Author:         user22
  Creation Date:  05/01/2018
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
##Requires -Modules "VMware.PowerCLI"
$Script:ProductName = "Move_ToNewVDS" #Fill this in. Do not put the "TEAM_" prefix
$ErrorActionPreference = "SilentlyContinue" #Maybe change to "SilentlyContinue" for Production.
Clear-Host
Write-Host "Importing VMware.PowerCLI Module now"
Import-Module -Name VMware.PowerCLI
Set-PowerCLIConfiguration -InvalidCertificateAction ignore -confirm:$false
Clear-Host

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

function Move_VDS
{
  [CmdletBinding()]
  Param
  (
    [parameter(Mandatory=$true,
    Position=0)]
    $vmhost,

    [parameter(Mandatory=$true,
    Position=1)]
    $oldNet,
  
    [parameter(Mandatory=$true,
    Position=2)]
    $newNet
  )

  Log_ToSplunk -Message "Moving VMs from Host $vmhost from $oldNet to $newNet"

  $VMs = (Get-VMHost -Name $vmhost | Get-VM | Where-Object { (Get-VM -Name $_.Name | Get-NetworkAdapter).NetworkName -eq $oldNet }).Name

  if($VMs -eq $null)
  {
    Log_ToSplunk "No VMs on host $vmhost use $oldNet"
    Write-Host "No VMs on host $vmhost use $oldNet"
    exit
  }

  foreach($VM in $VMs)
  {
    $adapters = Get-VM -Name $VM | Get-NetworkAdapter | Where-Object { $_.NetworkName -eq $oldNet}
    $fail = 0
    foreach($adapter in $adapters)
    {
      Set-NetworkAdapter -NetworkAdapter $adapter -NetworkName $newNet
      if($? -eq $true)
      {
        Log_ToSplunk -Message "$VM $adapter moved from $oldNet to $newNet" -status "success"
      }
      else 
      {
        Log_ToSplunk -Message "$VM $adapter failed to move from $oldnet to $newNet" -Status "fail"
        $fail++
      }
    }

    if($fail -eq 0)
    {
      Write-Host $VM + " network adapter(s) have succesfully been moved to $newNet"
    }
    elseif($fail -gt 0)
    {
      Write-Host "There was a problem moving one or more adapters network to $newNet on $VM.  See Splunk logs for details." -ForegroundColor Red
    }
  }
}

# Variables
#################################

$vCenter = "domainvc1.example.com"

# Script Starts
#################################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"

$flag = 1
do
{
  Write-Host "Connecting to vCenter: $($vCenter)"
  Connect-VIServer -Server $vCenter -Credential (Get-Credential)
  if($?)
  {
    $flag = 0
  }
}
while($flag -eq 1)

Clear-Host

$vmhost = Read-Host "Enter VMHost FQDN"
$oldnet = Read-Host "Enter Existing Network Name"
$newnet = Read-Host "Enter New Network Name"

Move_VDS -vmhost $vmhost -oldNet $oldnet -newNet $newnet

# Script Ends
#################################
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Exit