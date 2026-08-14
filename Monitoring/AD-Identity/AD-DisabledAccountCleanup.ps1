# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith

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
    AD-DisabledAccountCleanup.ps1

.DESCRIPTION
    		This script will scan the Disabled Accounts OU in AD for accounts disabled 30 Days and delete them.
    		It then creates a report that will be emailed to the Service Desk and PC Technicians. This report
    		will also include a list of users that will be deleted in the next batch (If ran weekly)

.FUNCTIONALITY
    		This script will scan the Disabled Accounts OU in AD for accounts disabled 30 Days and delete them.
    		It then creates a report that will be emailed to the Service Desk and PC Technicians. This report
    		will also include a list of users that will be deleted in the next batch (If ran weekly)

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#Import the Active Directory Module
import-module activedirectory

$oldDate = [DateTime]::Today.AddDays(-30)
$warnDate = [DateTime]::Today.AddDays(-23)
$AMSearchBase = "OU=Disabled Accounts,OU=Domain Services,DC=DOMAIN,DC=com"
$ShortRegion = "SSC"
$Region = "Corporate Accounts"
$delUsers = @()
$warnUsers = @()
$wlistUsers = @()
$30daysUsers = @()

##Scans AD for Disabled Users, in the Disabled Accounts OU
$disabledUsers = Get-ADUser -filter { (Enabled -eq $False) } -Searchbase $AMSearchBase -Searchscope 1 -Properties Name, SID, Enabled, LastLogonDate, Modified, info, description

foreach ($name in $disabledUsers)
{
	if ($name.info -ne "WHITELIST" -and $name.modified -le $oldDate)
	{
		Remove-ADUser -id $name.SID -confirm:$false
		$delUsers = $delUsers + $name
	}
	elseif ($name.info -eq "WHITELIST")
	{
		#Write-Host $name.name " is Whitelisted"
		$wlistUsers = $wlistUsers + $name
	}
	elseif ($name.info -ne "WHITELIST" -and $name.modified -le $warnDate)
	{
		#Write-Host $name.name " is will be deleted in the next run"
		$warnUsers = $warnUsers + $name
	}
	else
	{
		#Write-Host $name.name " was modified less than 30 days ago"
		$30daysUsers = $30daysUsers + $name
	}
}

$report = "c:\DisabledCleanup.htm"
##Clears the report in case there is data in it
Clear-Content $report
##Builds the headers and formatting for the report
Add-Content $report "<html>"
Add-Content $report "<head>"
Add-Content $report "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>"
Add-Content $report '<title>Domain Disabled Account Cleanup Report</title>'
add-content $report '<STYLE TYPE="text/css">'
add-content $report  "<!--"
add-content $report  "td {"
add-content $report  "font-family: Tahoma;"
add-content $report  "font-size: 11px;"
add-content $report  "border-top: 1px solid #999999;"
add-content $report  "border-right: 1px solid #999999;"
add-content $report  "border-bottom: 1px solid #999999;"
add-content $report  "border-left: 1px solid #999999;"
add-content $report  "padding-top: 0px;"
add-content $report  "padding-right: 0px;"
add-content $report  "padding-bottom: 0px;"
add-content $report  "padding-left: 0px;"
add-content $report  "}"
add-content $report  "body {"
add-content $report  "margin-left: 5px;"
add-content $report  "margin-top: 5px;"
add-content $report  "margin-right: 0px;"
add-content $report  "margin-bottom: 10px;"
add-content $report  ""
add-content $report  "table {"
add-content $report  "border: thin solid #000000;"
add-content $report  "}"
add-content $report  "-->"
add-content $report  "</style>"
Add-Content $report "</head>"
add-Content $report "<body>"

##This section adds tables to the report with individual content
##Table 1 for deleted users
add-content $report  "<table width='100%'>"
add-content $report  "<tr bgcolor='#CCCCCC'>"
add-content $report  "<td colspan='7' height='25' align='center'>"
add-content $report  "<font face='tahoma' color='#003399' size='4'><strong>The following users have been deleted (Report Only)</strong></font>"
add-content $report  "</td>"
add-content $report  "</tr>"
add-content $report  "</table>"
add-content $report  "<table width='100%'>"
Add-Content $report "<tr bgcolor=#CCCCCC>"
Add-Content $report  "<td width='20%' align='center'>Account Name</td>"
Add-Content $report "<td width='10%' align='center'>Modified Date</td>"
Add-Content $report "<td width='50%' align='center'>Description</td>"
Add-Content $report "</tr>"
if ($delUsers -ne $null)
{
	foreach ($name in $delUsers)
	{
		$AccountName = $name.name
		$LastChgd = $name.modified
		$UserDesc = $name.Description
		Add-Content $report "<tr>"
		Add-Content $report "<td>$AccountName</td>"
		Add-Content $report "<td>$LastChgd</td>"
		add-Content $report "<td>$UserDesc</td>"
	}
}
else
{
	Add-Content $report "<tr>"
	Add-Content $report "<td>No Accounts match</td>"
}
Add-content $report  "</table>"

##Table 2 for warning users
add-content $report  "<table width='100%'>"
add-content $report  "<tr bgcolor='#CCCCCC'>"
add-content $report  "<td colspan='7' height='25' align='center'>"
add-content $report  "<font face='tahoma' color='#003399' size='4'><strong>The following users will be deleted next week</strong></font>"
add-content $report  "</td>"
add-content $report  "</tr>"
add-content $report  "</table>"
add-content $report  "<table width='100%'>"
Add-Content $report "<tr bgcolor=#CCCCCC>"
Add-Content $report  "<td width='20%' align='left'>Account Name</td>"
Add-Content $report "<td width='10%' align='center'>Modified Date</td>"
Add-Content $report "<td width='50%' align='center'>Description</td>"
Add-Content $report "</tr>"
if ($warnUsers -ne $null)
{
	foreach ($name in $warnUsers)
	{
		$AccountName = $name.name
		$LastChgd = $name.modified
		$UserDesc = $name.Description
		Add-Content $report "<tr>"
		Add-Content $report "<td>$AccountName</td>"
		Add-Content $report "<td>$LastChgd</td>"
		add-Content $report "<td>$UserDesc</td>"
	}
}
else
{
	Add-Content $report "<tr>"
	Add-Content $report "<td>No Accounts match</td>"
}
Add-content $report  "</table>"

##Table 3 for whitelisted users
add-content $report  "<table width='100%'>"
add-content $report  "<tr bgcolor='#CCCCCC'>"
add-content $report  "<td colspan='7' height='25' align='center'>"
add-content $report  "<font face='tahoma' color='#003399' size='4'><strong>The following users are whitelisted</strong></font>"
add-content $report  "</td>"
add-content $report  "</tr>"
add-content $report  "</table>"
add-content $report  "<table width='100%'>"
Add-Content $report "<tr bgcolor=#CCCCCC>"
Add-Content $report  "<td width='20%' align='left'>Account Name</td>"
Add-Content $report "<td width='10%' align='center'>Modified Date</td>"
Add-Content $report "<td width='50%' align='center'>Description</td>"
Add-Content $report "</tr>"
if ($wlistUsers -ne $null)
{
	foreach ($name in $wlistUsers)
	{
		$AccountName = $name.name
		$LastChgd = $name.modified
		$UserDesc = $name.Description
		Add-Content $report "<tr>"
		Add-Content $report "<td>$AccountName</td>"
		Add-Content $report "<td>$LastChgd</td>"
		add-Content $report "<td>$UserDesc</td>"
	}
}
else
{
	Add-Content $report "<tr>"
	Add-Content $report "<td>No Accounts match</td>"
}
Add-content $report  "</table>"

##Table 4 for recently modified users
add-content $report  "<table width='100%'>"
add-content $report  "<tr bgcolor='#CCCCCC'>"
add-content $report  "<td colspan='7' height='25' align='center'>"
add-content $report  "<font face='tahoma' color='#003399' size='4'><strong>The following users were disabled in the last 30 days</strong></font>"
add-content $report  "</td>"
add-content $report  "</tr>"
add-content $report  "</table>"
add-content $report  "<table width='100%'>"
Add-Content $report "<tr bgcolor=#CCCCCC>"
Add-Content $report  "<td width='20%' align='left'>Account Name</td>"
Add-Content $report "<td width='10%' align='center'>Modified Date</td>"
Add-Content $report "<td width='50%' align='center'>Description</td>"
Add-Content $report "</tr>"
if ($30daysUsers -ne $null)
{
	foreach ($name in $30daysUsers)
	{
		$AccountName = $name.name
		$LastChgd = $name.modified
		$UserDesc = $name.Description
		Add-Content $report "<tr>"
		Add-Content $report "<td>$AccountName</td>"
		Add-Content $report "<td>$LastChgd</td>"
		add-Content $report "<td>$UserDesc</td>"
	}
}
else
{
	Add-Content $report "<tr>"
	Add-Content $report "<td>No Accounts match</td>"
}
Add-content $report  "</table>"

##This section closes the report formatting
Add-Content $report "</body>"
Add-Content $report "</html>"

##Assembles and sends completion email with DL information##
$emailFrom = "helpdesk@example.com"
$emailTo = "PCTechnicians@example.com; DomainHD@example.com"
$subject = "Domain Disabled Account Cleanup Script Report"
$smtpServer = "srv.example.com"
$body = Get-Content $report | Out-String

Send-MailMessage -To $emailTo -From $emailFrom -Subject $subject -BodyAsHtml -Body $body -SmtpServer $smtpServer
