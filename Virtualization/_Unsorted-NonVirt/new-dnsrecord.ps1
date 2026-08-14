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
    new-dnsrecord.ps1

.SYNOPSIS
  Creates of modifies DNS records for specified ESXi host.
 
.DESCRIPTION
  More in depth information.
  
.NOTES
  Version:        1.0
  Author:         user22
  Creation Date:  05/15/2018
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
$Script:ProductName = "NewDNSRecord" #Fill this in. Do not put the "TEAM_" prefix
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

function add_dnsentry
{
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory=$true,
        Position=0)]
        $HostName,

        [parameter(Mandatory=$true,
        Position=1)]
        $IP
    )

    $DC = "SRV-ADS-DC16"
    $adddnsrecord =
    {
        $IP = $args[0]
        $HostName = $args[1]
        Add-DnsServerResourceRecord -ZoneName "example.com" -IPv4Address $IP -A -TimeToLive "01:00:00" -Name $HostName
    }
    $removednsrecord =
    {
        $Hostname = $args[0]
        Get-DnsServerResourceRecord -ZoneName "example.com" | Where-Object {$_.HostName -eq "$($HostName)"} | Remove-DnsServerResourceRecord -Force -ZoneName "example.com"
    }

    #checks to see if entry needs to be modified or created
    $existingEntries = invoke-command -scriptblock {Get-DnsServerResourceRecord -ZoneName example.com} -ComputerName $DC -Credential $script:credential | Where-Object {$_.HostName -eq "$($HostName)"}

    #$creatednsentry = Add-DnsServerResourceRecord -ZoneName "example.com" -IPv4Address $IP -A -TimeToLive "01:00:00" -Name $HostName
    if(($existingEntries.HostName) -eq $Null)
    {
        Invoke-Command -ComputerName $DC -ScriptBlock $adddnsrecord -ArgumentList $IP,$HostName -Credential $script:credential
        if($?)
        {
            return $true
        }
        else
        {
            return $false
        }
    }
    else
    {
        Write-Host "Existing DNS entries found for $($hostname), removing before continuing." -ForegroundColor Yellow
        Log_ToSplunk -Message "Existing DNS entries found for $($hostname), removing before continuing."
        #$command = Get-DnsServerResourceRecord -ZoneName "example.com" | Where-Object {$_.HostName -eq "$($HostName)"} | Remove-DnsServerResourceRecord -Force -ZoneName "example.com"
        Invoke-Command -ComputerName $DC -ScriptBlock $removednsrecord -ArgumentList $HostName -Credential $script:credential
        if($?)
        {
            Log_ToSplunk -Message "Existing DNS entries removed for $($hostname)"
            Write-Host "Existing DNS entries removed for $($hostname), proceeding to create new entry"

            Invoke-Command -ComputerName $DC -ScriptBlock $adddnsrecord -ArgumentList $IP,$HostName -Credential $script:credential
            if($?)
            {
                return $true
            }
            else
            {
                return $false
            }
        }
    }
}

# Variables
#################################

# Below used to get, and check credentials
$flag = 1;
do
{
    Write-Host "Enter Admin Credentials" -ForegroundColor Yellow
    $username = Read-Host "Enter Admin Username"
    $password = Read-Host "Enter Password" -AsSecureString
    $script:credential = New-Object -TypeName System.Management.Automation.PSCredential($username,$password)

    $usercheck = $script:credential.UserName
    $passcheck = $script:credential.GetNetworkCredential().Password

    $CurrentDomain = "LDAP://" + ([ADSI]"").distinguishedName
    $domain = New-Object System.DirectoryServices.DirectoryEntry($CurrentDomain,$usercheck,$passcheck)

    if($domain.Name -eq $null)
    {
        Clear-Host
        Write-Host "Credentials invalid, please try again." -ForegroundColor Red
    }
    else 
    {
        $flag = 0;
    }
}
while($flag -eq 1)


# Script Starts
#################################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"

Clear-Host

$store = Read-Host "Enter UFO_NUMBER"
$hostname = $store + "ESXI"
#$hostname = Read-Host "Enter ESXi Hostname (eg: 1003ESXI)"

$nettypeselected = $false
do
{
    $networktype = Read-Host "Enter Network Type (new/old)"
    if($networktype -eq "old")
    {
        $IP = Read-Host "Enter the IP address"
        $nettypeselected = $true
    }
    elseif($networktype -eq "new")
    {
        $lastoct = Read-Host "Please supply last octet (99 unless on DHCP)"
        $IP = "10." + $($store.substring(0,2)) + "." + $($store.substring(2,2)) + "." + $lastoct
        $nettypeselected = $true
    }
    else 
    {
        Write-Host "Please specify a network type!" -ForegroundColor Red
    }
}
while($nettypeselected -eq $false)

$dnsentry = add_dnsentry -HostName $hostname -IP $IP
if($dnsentry -eq $true)
{
    Log_ToSplunk -Message "Operation completed succesfully. Static DNS entry created for $($hostname) with IP: $($IP)" -Status "success"
    Write-Host "Operation completed succesfully. Static DNS entry created for $($hostname) with IP: $($IP)" -ForegroundColor Green
}
else 
{
    Log_ToSplunk -Message "Operation failed.  Static DNS entry for $($hostname) could not be created." -Status "fail"
    Write-Host "Operation failed.  Static DNS entry for $($hostname) could not be created." -ForegroundColor Red
}

# Script Ends
#################################
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Exit