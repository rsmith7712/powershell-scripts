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
    Copy-GroupMembership.ps1

.SYNOPSIS
  Copies group membership from one AD group to another.
  
.NOTES
  Version:        1.0
  Author:         user22
  Creation Date:  05/27/2018
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0 
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Copies group membership from one AD group to another.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Initializations
#################################
$Script:ProductName = "Copy-GroupMembership" #Fill this in. Do not put the "TEAM_" prefix
$ErrorActionPreference = "SilentlyContinue" #Maybe change to "SilentlyContinue" for Production.
Import-Module -Name ActiveDirectory

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

function Copy-GroupMembership
{
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory=$true,
        Position=0)]
        $SourceGroup,

        [parameter(Mandatory=$true,
        Position=1)]
        $TargetGroup
    )

    $users = (Get-ADGroupMember -Identity $SourceGroup).samaccountname
    $targetusers = (Get-ADGroupMember -Identity $TargetGroup).samaccountname

    foreach($user in $users)
    {
        if($targetusers -contains $user)
        {
            Write-Host "$user is already in $TargetGroup"
        }
        else
        {
            Add-ADGroupMember -Identity $TargetGroup -Members $user
            if($?)
            {
                Write-Host "$user added to $TargetGroup"
                Log_ToSplunk -Message "$user added to $TargetGroup" -Status "success"
            }
        }
    }
}

# Variables
#################################

$flag1 = $false
#get source group
do
{
    $SourceGroup = Read-Host "Enter Source Group Name"
    $sourcecheck = Get-ADGroup -Filter * | Where-Object {$_.samaccountname -eq $SourceGroup}
    if($sourcecheck)
    {
        $flag1 = $true
    }
    else 
    {
        Write-Host "Cannot find $SourceGroup, please try again" -ForegroundColor Red
    }
} 
while($flag1 -eq $false)

$flag2 = $false
#get target group
do
{
    $TargetGroup = Read-Host "Enter Target Group Name"
    $targetcheck = Get-ADGroup -Filter * | Where-Object {$_.samaccountname -eq $TargetGroup}
    if($targetcheck)
    {
        $flag2 = $true
    }
    else 
    {
        Write-Host "Cannot find $TargetGroup, please try again" -ForegroundColor Red
    }
} while($flag2 -eq $false)

# Script Starts
#################################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"

Copy-GroupMembership -SourceGroup $SourceGroup -TargetGroup $TargetGroup

# Script Ends
#################################
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Exit