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
    Ping_Report_for_EventLog_Service.ps1

.DESCRIPTION
    		- Query specified server service status and availability -- (if applicable)
    		- Query each server for their system uptime (since their last reboot)
    		- Post HTML report on file share, and separately...
    		- Email HTML report to specific addresses

.FUNCTIONALITY
    		- Query specified server service status and availability -- (if applicable)
    		- Query each server for their system uptime (since their last reboot)
    		- Post HTML report on file share, and separately...
    		- Email HTML report to specific addresses

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

############################################# Define Servers & Services Variables

#### S1 -- Family: 
$Server1List = Get-Content "C:\Users\sysadmin\Desktop\serverlist_co.txt"
$Services1List = Get-Content "C:\Users\sysadmin\Desktop\serviceslist_co.txt"

############################################# Define other variables
$report = "C:\Users\sysadmin\Desktop\Ping_Report.htm" 

$smtphost = "smtpi.example.com" 
$from = "Ping_Status@example.com"
$to = "admin2@example.com"

$checkrep = Test-Path "C:\Users\sysadmin\Desktop\Ping_Report.htm"

If ($checkrep -like "True")
	{
		Remove-Item "C:\Users\sysadmin\Desktop\Ping_Report.htm"
	}

New-Item "C:\Users\sysadmin\Desktop\Ping_Report.htm" -Type File

############################################# ADD HTML Content 

Add-Content $report "<html>" 
Add-Content $report "<head>" 
Add-Content $report "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>" 
Add-Content $report '<title>Ping Status</title>' 
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
Add-Content $report "<body>" 
add-content $report  "<table width='100%'>" 
add-content $report  "<tr bgcolor='Lavender'>" 
add-content $report  "<td colspan='7' height='25' align='center'>"
add-content $report  "<font face='tahoma' color='#003399' size='4'><strong>Ping Status</strong></font>"
add-content $report  "</td>" 
add-content $report  "</tr>" 
add-content $report  "</table>" 
 
add-content $report  "<table width='100%'>" 
Add-Content $report "<tr bgcolor='IndianRed'>"
Add-Content $report  "<td width='10%' align='center'><B>Server</B></td>"
Add-Content $report  "<td width='10%' align='center'><B>Svr.Uptime</B></td>"
Add-Content $report "<td width='30%' align='center'><B>Service</B></td>" 
Add-Content $report  "<td width='10%' align='center'><B>Status</B></td>" 
Add-Content $report "</tr>"

############################################# FUNCTION - Get-UpTime

function Get-UpTime
{
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
		[Alias("CN")]
		[String]$ComputerName = $Env:ComputerName,
		[Parameter(Position = 1, Mandatory = $false)]
		[Alias("RunAs")]
		[System.Management.Automation.Credential()]
		$Credential = [System.Management.Automation.PSCredential]::Empty
	)
	process
	{
		"Uptime: {1:%d} Days {1:%h} Hours {1:%m} Minutes {1:%s} Seconds" -f $ComputerName,
		(New-TimeSpan -Seconds (Get-WmiObject Win32_PerfFormattedData_PerfOS_System -ComputerName $ComputerName -Credential $Credential).SystemUpTime)
	}
}

############################################# FUNCTION - Services Status 

Function servicestatus ($ServerList, $ServicesList)
{
foreach ($Server in $ServerList) 
	{
  foreach ($Service in $ServicesList)
		{
			$serviceStatus = get-service -ComputerName $Server -Name $Service
			$serverUptime = $Server | Get-UpTime
			
			if ($serviceStatus.status -eq "Running")
			{
				Write-Host $Server `t $serverUptime `t $serviceStatus.name `t $serviceStatus.status -ForegroundColor Green
				$svcName = $serviceStatus.name 
		        $svcState = $serviceStatus.status 
		        Add-Content $report "<tr>"
				Add-Content $report "<td bgcolor= 'GainsBoro' align=center>  <B> $Server</B></td>"
				Add-Content $report "<td bgcolor= 'GainsBoro' align=center>  <B> $serverUptime</B></td>"
		        Add-Content $report "<td bgcolor= 'GainsBoro' align=center>  <B>$svcName</B></td>" 
		        Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>$svcState</B></td>" 
		        Add-Content $report "</tr>" 
            }
	    	else 
            {
				Write-Host $Server `t $serverUptime `t $serviceStatus.name `t $serviceStatus.status -ForegroundColor Red 
		        $svcName = $serviceStatus.name 
		        $svcState = $serviceStatus.status 
		        Add-Content $report "<tr>"
				Add-Content $report "<td bgcolor= 'GainsBoro' align=center>$Server</td>"
				Add-Content $report "<td bgcolor= 'GainsBoro' align=center>$serverUptime</td>"
		        Add-Content $report "<td bgcolor= 'GainsBoro' align=center>$svcName</td>" 
		        Add-Content $report "<td bgcolor= 'Red' align=center><B>$svcState</B></td>"
		        Add-Content $report "</tr>" 
            }
		}
	}
}

############################################# Call Function 

#### S1 -- (01) -- 
servicestatus $Server1List $Services1List

############################################# Close HTMl Tables 

Add-content $report  "</table>" 
Add-Content $report "</body>" 
Add-Content $report "</html>" 

############################################# Send Email 

$subject = "Ping Status" 
$body = Get-Content "C:\Users\sysadmin\Desktop\serverlist_co.txt"
$smtp= New-Object System.Net.Mail.SmtpClient $smtphost 
$msg = New-Object System.Net.Mail.MailMessage $from, $to, $subject, $body 
$msg.isBodyhtml = $true 
$smtp.send($msg)

############################################# 
 
