# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith, Geoff Sweet

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
    DNS-getScavengingData.ps1

.SYNOPSIS
    Dump the DNS server name and scavenging settings for each DNS server in the domain.

.FUNCTIONALITY
    Prompts for Input

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712 
        PowerShell Scripts - DNS-getScavengingData
#>

Import-Module ActiveDirectory;

# Function - Logging file
function Logging($pingerror, $Computer, $DnsStatus)
{
	$outputfile = "\\<DOMAIN>\Shares\Install\UTILITY\Automation\logs\log_DnsScavengingData.txt";
	
	$timestamp = (Get-Date).ToString();
	
	$logstring = "Computer / DNS (reported in Hours): {0}, {1}" -f $Computer, $DnsStatus;
	
	"$timestamp - $logstring" | out-file $outputfile -Append;
	
	if ($pingerror -eq $false)
	{
		Write-Host "$timestamp - $logstring";
	}
	else
	{
		Write-Host "$timestamp - $logstring" -foregroundcolor red;
	}
	return $null;
}

# Query for a list of all domain controllers
$DCs = (GET-ADDOMAIN -Identity <DOMAIN>).ReplicadirectoryServers

# ForEach Loop - Process list of DCs and return lines with "scavenging" only in them 
foreach ($dc in $DCs)
{
	$output = dnscmd $DC /info
	$string = $output | Select-string "Scavenging"
	Write-host $DC
	Write-host $string
	Write-host ""
	
	Logging $False $DC $string;
}