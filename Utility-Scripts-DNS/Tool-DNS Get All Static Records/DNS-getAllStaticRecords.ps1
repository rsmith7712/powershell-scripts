# LEGAL
<# LICENSE
    MIT License, Copyright 2016 dverbern, Richard Smith

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
    DNS-getAllStaticRecords.ps1

.SYNOPSIS
    Get list of Static A records in DNS Zone of your choice -- Does NOT run from Win7, Must be newer OS

.FUNCTIONALITY
    Prompts for Input

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712 
        PowerShell Scripts - DNS-getAllStaticRecords
#>

Clear-Host
$PathToReport = "C:\"
$To = "EMAIL ADDRESS"
$From = "GetAllStaticDNSRecords@<DOMAIN>.com"
$SMTPServer = "SMTP SERVER"
$ZoneName = "DOMAIN"
$DomainController = "DOMAIN CONTROLLER FQDN"


#Get Current date for input into report
$CurrentDate = Get-Date -Format "MMMM, yyyy"

#region Functions
Function Set-AlternatingRows
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)]
		[object[]]$HTMLDocument,
		[Parameter(Mandatory = $True)]
		[string]$CSSEvenClass,
		[Parameter(Mandatory = $True)]
		[string]$CSSOddClass
	)
	Begin
	{
		$ClassName = $CSSEvenClass
	}
	Process
	{
		[string]$Line = $HTMLDocument
		$Line = $Line.Replace("<tr>", "<tr class=""$ClassName"">")
		If ($ClassName -eq $CSSEvenClass)
		{
			$ClassName = $CSSOddClass
		}
		Else
		{
			$ClassName = $CSSEvenClass
		}
		$Line = $Line.Replace("<table>", "<table width=""20%"">")
		Return $Line
	}
}
#endregion

$Header = @"
<style>
TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #D8E4FA;}
TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
.odd  { background-color:#ffffff; }
.even { background-color:#dddddd; }
</style>
<title>Static DNS A Records across all Nodes of $ZoneName Domain for $CurrentDate</title>
"@

$Report = Get-DnsServerResourceRecord -ZoneName $ZoneName -ComputerName $DomainController -RRType A | Where Timestamp -eq $Null | Select -Property HostName, RecordType -ExpandProperty RecordData
$NumberOfRecords = $Report | Measure-Object HostName | Select-Object -Property Count
$Report = $Report | Select HostName, RecordType, IPv4Address |
ConvertTo-Html -Head $Header -PreContent "<p><h2>Static DNS A Records across all Nodes of $ZoneName Domain for $CurrentDate</h2></p><br><p><h3>$NumberOfRecords Records listed</h3></p>" |
Set-AlternatingRows -CSSEvenClass even -CSSOddClass odd
$Report | Out-File $PathToReport\Output_AD_GetListStaticARecords.html
Send-MailMessage -To $To -From $From -Subject "Static DNS A Records across all Nodes of $ZoneName Domain for $CurrentDate" -Body ($Report | Out-String) -BodyAsHtml -SmtpServer $SMTPServer

Write-Host "Script completed!" -ForegroundColor Green
