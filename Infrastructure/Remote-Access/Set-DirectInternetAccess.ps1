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
    Set-DirectInternetAccess.ps1

.SYNOPSIS
  Removes a specified account from ISAGROUP19 and adds account to Meraki security group.
  
.NOTES
  Version:        1.0
  Author:         user22
  Creation Date:  07/10/2018
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Removes a specified account from ISAGROUP19 and adds account to Meraki security group.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Initializations
#################################
$Script:ProductName = "Set-DirectInternetAccess" #Fill this in. Do not put the "TEAM_" prefix
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

function Set-DirectInternetAccess
{
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory=$true,
        Position=0)]
        $UFO_NUMBER
    )

    $str = $UFO_NUMBER + "str"
    $mgr = $UFO_NUMBER + "mgr"

    $accounts = @()
    $accounts += $str
    $accounts += $mgr

    $isa = (Get-ADGroupMember -Identity isagroup19).samaccountname
    $meraki = (Get-ADGroupMember -Identity "Meraki_Stores").samaccountname

    foreach($account in $accounts)
    {
        if($isa -contains $account)
        {
            Remove-ADGroupMember -Identity "isagroup19" -Members $account
            if($?)
            {
                Log_ToSplunk -Message "$account removed from ISAGROUP19"
                Write-Host "$account removed from ISAGROUP19"
            }
            else 
            {
                Log_ToSplunk -Message "Unable to remove $account from ISAGROUP19"
                Write-Host "Unable to remove $account from ISAGROUP19" -ForegroundColor Red
            }
        }
        else 
        {
            Log_ToSplunk -Message "$account not found in ISAGROUP19"
            Write-Host "$account not found in ISAGROUP19"
        }

        if($meraki -contains $account)
        {
            Log_ToSplunk -Message "$account is already a member of Meraki_Stores"
            Write-Host "$account is already a member of Meraki_Stores"
        }
        else 
        {
            Add-ADGroupMember -Identity "Meraki_Stores" -Members $account
            if($?)
            {
                Log_ToSplunk -Message "$account succesfully added to Meraki_Stores" -Status "Success"
                Write-Host "$account succesfully added to Meraki_Stores"
            }
            else 
            {
                Log_ToSplunk -Message "Unable to add $account to Meraki_Stores" -Status "Fail"
                Write-host "Unable to add $account to Meraki_Stores" -ForegroundColor Red
            }
        }
    }
}

function Get-UFO_NUMBER
{
    $flag = $false
do
{
    $store = Read-Host "Enter UFO_NUMBER"
    if($store.Length -gt 4)
    {
        Write-Host "You have entered an incorrect UFO_NUMBER, please try again." -ForegroundColor Red
    }
    else 
    {
        $flag = $true
    }
}
until($flag -eq $true)
return $store
}

# Script Starts
#################################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"

$continue = $true
do
{
    $store = Get-UFO_NUMBER
    Set-DirectInternetAccess -UFO_NUMBER $store
    $choice = Read-Host "Would you like to run this script again? (y/n)"
    if($choice -eq "n")
    {
        $continue = $false
    }
}
until($continue -eq $false)

# Script Ends
#################################
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Exit