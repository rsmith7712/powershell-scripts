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
    Update-DNS_2.ps1

.SYNOPSIS
  Updates DNS server settings on all network adapters.
 
.DESCRIPTION
  Fixes a DNS SNAFU
  'Tell him "nice" for me.' - user22
  'I'm getting too old for this sh*t.' - user26
  
.NOTES
  Version:        1.0
  Author:         user26
  Creation Date:  11/14/2018
  Purpose/Change: Initial Script Development

.HISTORY

.FUNCTIONALITY
    Fixes a DNS SNAFU
      'Tell him "nice" for me.' - user22
      'I'm getting too old for this sh*t.' - user26

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Initializations
#################################
$Script:ProductName = "fixDNS" #Fill this in. Do not put the "TEAM_" prefix
$ErrorActionPreference = "SilentlyContinue" #Maybe change to "SilentlyContinue" for Production.

$OU = "OU=Corporate Computers,DC=domain,DC=com"
$dnsservers =@("0.0.0.0","0.0.0.0")

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

	$SB = {
		param($uri,$header,$body)
		Invoke-WebRequest -Uri $uri -Method Post -Headers $header -Body $body | Out-Null
	}

	$job = Start-Job -scriptblock $SB -argumentlist @($uri,$header,$body)
	$timeout = 10
	Wait-Job $job -Timeout $timeout
	Stop-Job $job
	Receive-Job $job
	Remove-Job $job
}
    
# Script Starts
#################################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"
$Computers = (Get-ADComputer -Filter * -SearchBase $OU).name
$ComputerCount = $Computers.count
$TotalCount = 0

ForEach($Computer in $Computers){
    If($TotalCount % 10 -eq 0){ # Every 10 machines, it clears the host and writes a new message.
        Clear-Host
        Write-Host "There have been $($TotalCount) of $($ComputerCount) computers modified."
    }
    Clear-Variable Adapters,Number,change
    If(Test-Connection $Computer -Quiet -Count 2){
		$Adapters = (get-wmiobject win32_networkadapterconfiguration -computername $Computer -Filter 'IPEnabled=true').Index
        $Number = $Adapters.Count
        Log_ToSplunk -Message "$Number NICs found on $($Computer)." -Type "Log" -Status "Informational"
        ForEach($Adapter in $Adapters){
            $change = get-wmiobject win32_networkadapterconfiguration -computername $Computer | where-object {$_.index -eq $Adapter} 
            $change.SetDNSServerSearchOrder($DNSservers) | out-null
            If($true -eq $?){
                Log_ToSplunk -Message "Changed DNS settins on adapter with index $($Adapter) on $($Computer)." -Type "Log" -Status "Informational"
            }
            else {
                Log_ToSplunk -Message "Failed to change DNS settins on adapter with index $($Adapter) on $($Computer)." -Type "Log" -Status "Informational"
            }
        }
    }
    else {
        Log_ToSplunk -Message "$($Computer) is offline." -Type "Log" -Status "Informational"
    }
    $TotalCount ++
}
# Script Ends
#################################
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Exit