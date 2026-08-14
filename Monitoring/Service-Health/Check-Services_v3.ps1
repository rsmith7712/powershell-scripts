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
    Check-Services_v3.ps1

.DESCRIPTION
            - All servers and services are broken out by Server Group
    		- Query specified server services status and availability -- (if specified)
    		- Query each server for their system uptime (since their last reboot)
    		- Post HTML report on file share, and separately...
    		- Email HTML report to specific addresses

.FUNCTIONALITY
            - All servers and services are broken out by Server Group
    		- Query specified server services status and availability -- (if specified)
    		- Query each server for their system uptime (since their last reboot)
    		- Post HTML report on file share, and separately...
    		- Email HTML report to specific addresses

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#
Param (
    [Paramter(Mandatory=$true)]
    [string]$script:ServerGroup
)
#>

[string]$Script:ServerGroup = $args[0]

If([string]::IsNullOrEmpty($Script:ServerGroup))
{
    $title = "WSUS Server Group Service Check"
    $message = "Which Server Group?"

    $Pilot = New-Object System.Management.Automation.Host.ChoiceDescription "&Pilot", `
        "Checks the services of all servers in the Pilot group."

    $Group1 = New-Object System.Management.Automation.Host.ChoiceDescription "Group&1", `
        "Checks the services of all servers in Group1."

    $Group2 = New-Object System.Management.Automation.Host.ChoiceDescription "Group&2", `
        "Checks the services of all servers in Group2."

    $DMZ = New-Object System.Management.Automation.Host.ChoiceDescription "&DMZ", `
        "Checks the services of all servers in the DMZ."
    
    $Quit = New-Object System.Management.Automation.Host.ChoiceDescription "&Cancel", `
        "Quits the script"

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($Pilot,$Group1,$Group2,$DMZ,$Quit)

    $Script:ServerGroup = $host.ui.PromptForChoice($title, $message, $options, 4)
}
If($Script:ServerGroup -ge 3)
{
    Write-Host "You've chosen to cancel the script or entered a non-existant Server Group. Script exiting in 5 seconds."
    Start-Sleep 5
    Exit
}
############################################# Initializations
$script:script_filepath = $MyInvocation.MyCommand.Path
$script:script_dir = Split-Path -Parent $script:script_filepath
$ErrorActionPreference = "SilentlyContinue"

############################################# Functions
function Get-UpTime($ComputerName)
{
	$Uptime = ((Get-Date) - ([wmi]'').ConvertToDateTime((Get-WmiObject win32_operatingsystem -ComputerName $ComputerName).LastBootUpTime)).ToString("dd\-hh\-mm\-ss")
	$Uptime = $Uptime -split '-'
	$WordyUptime = "Uptime: $($Uptime[0]) Days $($Uptime[1]) Hours $($Uptime[2]) Minutes $($Uptime[3]) Seconds"
	Return $WordyUptime
}

Function Get-ServiceStatus($Server,$Service,$Report,$serverUptime)
{
    $serviceStatus = get-service -ComputerName $Server -Name $Service
    
    if ($serviceStatus.status -eq "Running")
    {
        Write-Host $Server `t $serverUptime `t $serviceStatus.name `t $serviceStatus.status -ForegroundColor Green
        $svcName = $serviceStatus.name
        $svcState = $serviceStatus.status
        Add-Content $report "<tr>"
        Add-Content $report "<td bgcolor= 'GainsBoro' align=center><B>$Server</B></td>"
        Add-Content $report "<td bgcolor= 'GainsBoro' align=center><B>$serverUptime</B></td>"
        Add-Content $report "<td bgcolor= 'GainsBoro' align=center><B>$svcName</B></td>"
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

Function Send-Email($HTML,$ServerGroup)
{
    $To = "SysAdmins@example.com"
    $From = "WSUS ServerGroup$($ServerGroup) <wsus_post_tasks@example.com>"
    $smtphost = "smtpi.example.com"
    $subject = "WSUS ServerGroup$($ServerGroup) Services Status"
    #$body = Get-Content "\\SERVER\SHARE\...\Check_WSUS_ServerGroup2_Services.htm"
    $body = Get-Content $HTML
    $smtp = New-Object System.Net.Mail.SmtpClient $smtphost
    $msg = New-Object System.Net.Mail.MailMessage $from, $to, $subject, $body
    $msg.isBodyhtml = $true
    $smtp.send($msg)

}

Function PingTest($Computer)
{
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "ping.exe"
    $pinfo.Arguments = "$Computer -t"
    $pinfo.UseShellExecute = $false
    $pinfo.CreateNoWindow = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.RedirectStandardError = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $pinfo

    # Start the process
    $process.Start() | Out-Null

    # Wait a while for the process to do something
    Start-Sleep -Seconds 5

    # If the process is still active kill it
    if (!$process.HasExited) {
        $process.Kill()
        }
    # get output from stdout and stderr
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()

    # check output for success information, you may want to check stderr if stdout if empty
    if ($stdout.Contains("Reply from")) {
        # Write to log file that machine is online.
        Return "Online"
        } 
    elseif ($stdout.Contains("Ping request could not")) {
        # Write to log file that machine doesn't have DNS entry.
        Return "No DNS Entry"
        }
    else {
        # Write to log file that machine is offline but has DNS entry.
        Return "Offline"
        }
}

Function Add-HTML($Report,$Type,$ServerGroup)
{
    If($Type -eq "Open")
    {
        Add-Content $report "<html>"
        Add-Content $report "<head>"
        Add-Content $report "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>"
        Add-Content $report "<title>WSUS ServerGroup$ServerGroup Services Status</title>"
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
        add-content $report  "<font face='tahoma' color='#003399' size='4'><strong>WSUS ServerGroup$ServerGroup Service Status</strong></font>"
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
    }
    ElseIf($Type -eq "Close")
    {
        Add-content $report  "</table>"
        Add-Content $report "</body>"
        Add-Content $report "</html>"
    }
}

############################################# Script
$report = "\\SERVER\SHARE\...\Check_WSUS_ServerGroup$($Script:ServerGroup)_Services.htm"
If(Test-Path $report)
{
    Remove-Item $report -force
    New-Item $report -Type File
}

Add-HTML $report "Open" $script:ServerGroup # Creates the beginning of the html report file

$WSUStargets = Import-CSV "\\SERVER\SHARE\...\WSUS_ServerGroup$($Script:ServerGroup).csv"

$TotalCount = $WSUStargets.count
$Count = 0
Write-Host "There are $TotalCount servers in this group." -ForegroundColor Yellow

ForEach($Target in $WSUStargets)
{
    $Count++
    If($Count.substring(1,1) -eq "0")
    {
        Write-Host "$Count Servers completed out of $TotalCount Total." -ForegroundColor Yellow
    }
    If($Target.ServerName.substring(0,1) -eq "#") # Skips machines that are commented out in the CSV.
    {
        Continue
    }
    $ServerStatus = PingTest $Target.ServerName
    If($ServerStatus -eq "Online")
    {
        $Services = $Target.Services -split ';' # The services are semi-colon delimited in the csv
        $Uptime = Get-UpTime $Target.ServerName # Grab the uptime here once and pass it through
        ForEach($Service in $Services)
        {
            Get-ServiceStatus $Target.ServerName $Service $report $Uptime
        }
    }
    Else
    {
        Write-Host $Target.ServerName `t $ServerStatus -ForegroundColor Red
        Add-Content $report "<tr>"
        Add-Content $report "<td bgcolor= 'GainsBoro' align=center>$($Target.Servername)</td>"
        Add-Content $report "<td bgcolor= 'GainsBoro' align=center><B>N/A</B></td>"
        Add-Content $report "<td bgcolor= 'GainsBoro' align=center></td>"
        Add-Content $report "<td bgcolor= 'Orange' align=center><B>$ServerStatus</B></td>"
        Add-Content $report "</tr>"
    }
}

Add-HTML $report "Close" $script:ServerGroup # Closes the html report file

Send-Email $report $Script:ServerGroup