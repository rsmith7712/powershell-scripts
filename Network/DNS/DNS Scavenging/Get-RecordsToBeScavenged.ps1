#Requires -Module ActiveDirectory,DnsServer 
# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Adam Bertram, Richard Smith

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
   - Get-RecordsToBeScavenged.ps1

.SYNOPSIS
    - This script will report on all dynamic DNS records in a particular
	DNS zone that are at risk of being scavenged by the DNS scavenging
	process.

.FUNCTIONALITY
    - Prompts for Input, or Does It?
	
	.EXAMPLE 
    PS> Get-RecordsToBeScavenged.ps1 -DnsZone myzone -WarningDays 5 
  
    This example will find all DNS records in the zone 'myzone' that are
	set to be scavenged within 5 days. 

	.PARAMETER DnsServer 
		The DNS server that will be queried 

	.PARAMETER DnsZone 
		The DNS zone that will be used to find records 

	.PARAMETER WarningDays 
		The number of days ahead of scavenge time you'd like to report on.
		By default, this script only displays DNS records set to be
		scavenged within 1 day.

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

[CmdletBinding()]
[OutputType('System.Management.Automation.PSCustomObject')]
param (
	[Parameter(Mandatory)]
	[string]$DnsZone,
	[Parameter()]
	[string]$DnsServer = (Get-ADDomain).ReplicaDirectoryServers[0],
	[Parameter()]
	[int]$WarningDays = 1
)
begin{
	function Get-DnsHostname ($IPAddress){
		## Use nslookup because it's much faster than any other cmdlet 
		$Result = nslookup $IPAddress 2> $null
		$Result | where { $_ -match 'name' } | foreach {
			$_.Replace('Name:    ', '')
		}
	}
	Function Test-Ping ($ComputerName){
		try{
			$oPing = new-object system.net.networkinformation.ping;
			if (($oPing.Send($ComputerName, 200).Status -eq 'TimedOut')){
				$false;
			}
			else{
				$true
			}
		}
		catch [System.Exception]{
			$false
		}
	}
}
process{
	try{
		## Check if scavenging and aging is even enabled on the server and zone 
		$ServerScavenging = Get-DnsServerScavenging -Computername $DnsServer
		$ZoneAging = Get-DnsServerZoneAging -Name $DnsZone -ComputerName $DnsServer
		if (!$ServerScavenging.ScavengingState){
			Write-Warning "Scavenging not enabled on server '$DnsServer'"
			$NextScavengeTime = 'N/A'
		}
		else{
			$NextScavengeTime = $ServerScavenging.LastScavengeTime + $ServerScavenging.ScavengingInterval
		}
		if (!$ZoneAging.AgingEnabled){
			Write-Warning "Aging not enabled on zone '$DnsZone'"
		}
		
		## A record won't be scavengable until the refresh + no-refresh period
		## has elapsed. Set a threshold of this time plus a buffer to give the
		## user a heads up ahead of time. 
		$StaleThreshold = ($ZoneAging.NoRefreshInterval.Days + $ZoneAging.RefreshInterval.Days) + $WarningDays
		
		## Find all dynamic DNS host records in the zone that haven't updated
		## their timestamp in a long time ensuring to only include the hosts
		## ending with the zone name. If not, by default, Get-DnsServerResourceRecord 
		## will include a record with and without the zone name appended 
		$StaleRecords = Get-DnsServerResourceRecord -ComputerName $DnsServer -ZoneName $DnsZone -RRType A | where { $_.TimeStamp -and ($_.Timestamp -le (Get-Date).AddDays("-$StaleThreshold")) -and ($_.Hostname -like "*.$DnsZone") }
		foreach ($StaleRecord in $StaleREcords){
			## Get the IP address of the host to preform a reverse DNS lookup later 
			$RecordIp = $StaleRecord.RecordData.IPV4Address.IPAddressToString
			## Perform a reverse DNS lookup to find the actual hostname for that IP address. 
			## Sometimes when a record has been out of commission for a long time duplicate 
			## records can be created and the actual hostname for the IP address doesn't match 
			## the old DNS record hostname anymore. 
			$ActualHostname = Get-DnsHostname $RecordIp
			if ($ActualHostname){
				## There's a PTR record for the host record.  Ping the hostname to see if it's 
				## still online.  This is to only pay attention to the computers that may still 
				## be online but have a problem updating their record. 
				$HostOnline = Test-Ping -Computername $ActualHostname
			}
			else{
				$HostOnline = 'N/A'
			}
			[pscustomobject]@{
				'Server' = $DnsServer
				'Zone' = $DnsZone
				'RecordHostname' = $StaleRecord.Hostname
				'RecordTimestamp' = $StaleRecord.Timestamp
				'IsScavengable' = (@{ $true = $false; $false = $true }[$NextScavengeTime -eq 'N/A'])
				'ToBeScavengedOn' = $NextScavengeTime
				'ValidHostname' = $ActualHostname
				'RecordMatchesValidHostname' = $ActualHostname -eq $StaleRecord.Hostname
				'HostOnline' = (@{ $true = $HostOnline; $false = 'N/A' }[$ActualHostname -eq $StaleRecord.Hostname])
			}
		}
	}
	catch{
		Write-Error $_.Exception.Message
	}
}