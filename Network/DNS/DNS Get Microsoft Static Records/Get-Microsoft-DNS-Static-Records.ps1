# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith, Eric Rocconi

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
    Get-Microsoft-DNS-Static-Records.ps1

.SYNOPSIS
    PowerShell script to Get all dns static dns records in a specific zone.

.FUNCTIONALITY
    Prompts for Input

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712 
        PowerShell Scripts - Get-Microsoft_DNS_Static_Records
#>

Import-Module ActiveDirectory

# VARIABLES 
$ServerName = "DOMAIN CONTROLLER.DOMAIN.com"
$ContainerName = "DOMAIN.com"

foreach ($Server in $ServerName) {
	
	Get-WmiObject -ComputerName $Server -Namespace "root\MicrosoftDNS" -Class "MicrosoftDNS_AType" `
	-Filter "ContainerName = '$ContainerName' AND TimeStamp=0" `
	| Select-Object OwnerName, IPAddress, TextRepresentation, TTL, @{ n = "TimeStamp"; e = { "Static" } } | Export-Csv -Path c:\static_DNS_entries.csv -Encoding ascii -NoTypeInformation
	
}