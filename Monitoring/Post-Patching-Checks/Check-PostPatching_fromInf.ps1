<#	
	.NOTES
	===========================================================================
     Created on:   	10/12/2016 10:05 AM
     Last Modified: 10/09/2017 
     Created by:   	admin2@example.com
     Last Modified By: user4@example.com
	 Organization: 	Domain, Inc.
	 Filename:     	Check-PostPatching.ps1
	===========================================================================
	.EXAMPLE
        Powershell.exe -executionpolicy bypass -file .\Check-PostPatching.ps1 1
    .DESCRIPTION
        - All servers and services are broken out by Server Group
		- Query specified server services status and availability -- (if specified)
		- Query each server for their system uptime (since their last reboot)
		- Post HTML report on file share, and separately... 
		- Email HTML report to specific addresses

	.ToDo
		- 
#>
[string]$Script:ServerGroup = $args[0]

############################################# Initializations
$script:script_filepath = $MyInvocation.MyCommand.Path
$script:script_dir = Split-Path -Parent $script:script_filepath
$ErrorActionPreference = "SilentlyContinue"

$wsusServer = "SRV-WSUS-APP1.example.com"
$servicesList = "\\SERVER\SHARE\...\FullServiceList.csv"
############################################# Functions
function Get-UpTime($ComputerName)
{
	$UptimeBase = ((Get-Date) - ([wmi]'').ConvertToDateTime((Get-WmiObject win32_operatingsystem -ComputerName $ComputerName).LastBootUpTime)).ToString("dd\:hh\:mm")
	$Uptime = $UptimeBase -split ':'
    $WordyUptime = "$($Uptime[0]) Days $($Uptime[1]) Hours $($Uptime[2]) Minutes"
    $BruskUptime = "$($UptimeBase)"
	Return $BruskUptime
}

Function Get-ServiceStatus($Server,$Service,$Report,$serverUptime)
{
    $InitialStatus = get-service -ComputerName $Server -Name $Service
    If($? -eq $False) # Service doesn't exist on the specified server. Likely an error in the service list.
    {
        Write-Host $Server `t $serverUptime `t $Service `t "Service Not Found" -ForegroundColor Red
        Add-Content $report "<tr>"
        Add-Content $report "<td bgcolor= 'GainsBoro' align=center>$Server</td>"
        Add-Content $report "<td bgcolor= 'GainsBoro' align=center>$serverUptime</td>"
        Add-Content $report "<td bgcolor= 'Red' align=center><B>$Service not found. Please validate Service Name.</B></td>"
        Add-Content $report "<td bgcolor= 'Red' align=center><B>Not Found</B></td>"
        Add-Content $report "</tr>"
        Return # Exits the function
    }
    elseif($InitialStatus.status -eq "Stopped") # Attempts to start the service before doing a final check
    {
        $StartFlag = 1
        Get-Service -ComputerName $Server -Name $Service | Start-Service
        Start-Sleep 5
    }

    $ServiceStatus = get-service -ComputerName $Server -Name $Service
    If($serviceStatus.status -eq "Running")
    {
        #Write-Host $Server `t $serverUptime `t $serviceStatus.name `t $serviceStatus.status -ForegroundColor Green
        $svcName = $serviceStatus.name
        If($StartFlag -eq 1)
        {
            $svcState = "Running. Manually Started."
            $bgcolor = "'Yellow'"
        }
        Else
        {
            $svcState = $serviceStatus.status
            $bgcolor = "'Aquamarine'"
        }
        Add-Content $report "<tr>"
        Add-Content $report "<td bgcolor= 'GainsBoro' align=center><B>$Server</B></td>"
        Add-Content $report "<td bgcolor= 'GainsBoro' align=center><B>$serverUptime</B></td>"
        Add-Content $report "<td bgcolor= 'GainsBoro' align=center><B>$svcName</B></td>"
        Add-Content $report "<td bgcolor= $bgcolor align=center><B>$svcState</B></td>"
        Add-Content $report "</tr>"
    }
    else
    {
        Write-Host $Server `t $serverUptime `t $serviceStatus.name `t $serviceStatus.status -ForegroundColor Red
        $Script:ServiceErrors ++
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
    $From = "WSUS Post Patching Report <wsus_post_tasks@example.com>"
    $smtphost = "smtpi.example.com"
    $subject = "WSUS Group $($ServerGroup) Post-Patching Status"
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
    $process.Start() | Out-Null # Start the process
    Start-Sleep -Seconds 5 # Wait a while for the process to do something
    If (!$process.HasExited) { # If the process is still active kill it
        $process.Kill()
        }
    $stdout = $process.StandardOutput.ReadToEnd() # get output from stdout and stderr
    $stderr = $process.StandardError.ReadToEnd()
    if ($stdout.Contains("Reply from")) { # check output for success information, you may want to check stderr if stdout if empty
        Return "Online" # Write to log file that machine is online.
        } 
    elseif ($stdout.Contains("Ping request could not")) {
        Return "No DNS Entry" # Write to log file that machine doesn't have DNS entry.
        }
    else {
        Return "Offline" # Write to log file that machine is offline but has DNS entry.
        }
}

Function Add-HTML($Report,$Type,$ServerGroup)
{
    If($Type -eq "Open")
    {
        $StartTime = Get-Date -Format MM/dd/yy-HH:mm
        Add-Content $report "<html>"
        Add-Content $report "<head>"
        Add-Content $report "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>"
        Add-Content $report "<title>WSUS Group ""$ServerGroup"" Services Status - Executed by $ENV:USERNAME at $StartTime</title>"
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
        add-content $report  "<font face='tahoma' color='#003399' size='4'><strong>WSUS Group $ServerGroup Services Report- Executed by $ENV:USERNAME at $StartTime</strong></font>"
        add-content $report  "</td>"
        add-content $report  "</tr>"
        add-content $report  "</table>"

        add-content $report  "<table width='100%'>"
        Add-Content $report "<tr bgcolor='IndianRed'>"
        Add-Content $report  "<td width='10%' align='center'><B>Server</B></td>"
        Add-Content $report  "<td width='10%' align='center'><B>Uptime - DD:HH:MM</B></td>"
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

############################################# Script Start
If([string]::IsNullOrEmpty($Script:ServerGroup))
{
    $title = "WSUS Server Group Service Check"
    $message = "Which Server Group?"

    $Pilot = New-Object System.Management.Automation.Host.ChoiceDescription "Server &Pilot", `
        "Checks the services of all servers in the Pilot group."

    $Group1 = New-Object System.Management.Automation.Host.ChoiceDescription "Server Group&1", `
        "Checks the services of all servers in Group1."

    $Group2 = New-Object System.Management.Automation.Host.ChoiceDescription "Server Group&2", `
        "Checks the services of all servers in Group2."

    $DMZ = New-Object System.Management.Automation.Host.ChoiceDescription "&DMZ", `
        "Checks the services of all servers in the DMZ."
    
    $Quit = New-Object System.Management.Automation.Host.ChoiceDescription "&Cancel", `
        "Quits the script"

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($Pilot,$Group1,$Group2,$DMZ,$Quit)

    $Script:ServerGroup = $host.ui.PromptForChoice($title, $message, $options, 4)
}

Switch ($Script:ServerGroup)
{
    0{$Script:ServerGroup = "Server Pilot"}
    1{$Script:ServerGroup = "Server Systems"}
    2{$Script:ServerGroup = "Server Systems 2"}
    3{$Script:ServerGroup = "DMZ Servers"}
    4{
        Write-Host "You've chosen to cancel the script. Script exiting in 5 seconds."
        Start-Sleep 5
        Exit 1
    }
    default{
        Write-Host "You've entered a non-existant Server Group. Script exiting in 5 seconds."
        Start-Sleep 5
        Exit 1
    }
}

# Imports Server List from WSUS
# http://techibee.com/powershell/find-list-of-computerstargets-in-a-wsus-group-using-powershell/2139
[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
If($ENV:COMPUTERNAME -eq $wsusServer)
{
    $wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer()
}
Else
{            
    $wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($wsusServer,$False,8530)
}
If(!($?))
{
    Write-Host "This system doesn't have the WSUS console installed. Either install the console or run this script directly on $($wsusServer)"
    Exit 1
}
#$wsus.GetComputerTargetGroups()
$mygroup = $wsus.GetComputerTargetGroups() | Where-Object {$_.Name -eq $Script:ServerGroup}
$wsusImport = $mygroup.GetComputerTargets() | Select-Object -ExpandProperty FullDomainName
$wsusImport = $wsusImport | ForEach-Object{$_.Split(".") | Select-Object -First 1} #Removes FQDN, for testing.

# Gets service info only for the servers in this Server Group.
$WSUSservices = Import-CSV $servicesList
$WSUStargets = $WSUSservices.Where({$wsusImport -contains $_.ServerName})

# Creates HTML Report and Adds Header Info
$report = "\\SERVER\SHARE\...\Check_WSUS_ServerGroup$($Script:ServerGroup)_Services.htm"
If(Test-Path $report)
{
    Remove-Item $report -force
    New-Item $report -Type File
}
Add-HTML $report "Open" $script:ServerGroup # Creates the beginning of the html report file

# Basic Info for User
$Script:ServiceErrors = 0
$Script:OfflineServers = 0
$TotalCount = $WSUStargets.count
$Count = 0
$Timer = [diagnostics.stopwatch]::StartNew()
$Mins = 0
Write-Host "There are $TotalCount servers in this group." -ForegroundColor Yellow

# Checks Services, Adds Info to Report, and Displays Info to User
ForEach($Target in $WSUStargets)
{
    $Count ++
    $TimeCheck = $Timer.Elapsed.Minutes
    If([int]$TimeCheck -gt [int]$Mins)
    {
        [int]$Mins = [int]$TimeCheck
        Clear-Host
        Write-Host "`n$Count Servers completed out of $TotalCount Total." -ForegroundColor Yellow
        Write-Host "`nThere have been $($Script:ServiceErrors) Service Errors encountered so far." -ForegroundColor Yellow
        Write-Host "`nThere have been $($Script:OfflineServers) Offline Servers.`n`n" -ForegroundColor Yellow
    }
    $ServerStatus = PingTest $Target.ServerName
    $Services = $Target.Services -split ';' # The services are semi-colon delimited in the csv
    If($ServerStatus -eq "Online")
    {
        $Uptime = Get-UpTime $Target.ServerName # Grab the uptime here once and pass it through
        ForEach($Service in $Services)
        {
            Get-ServiceStatus $Target.ServerName $Service $report $Uptime
        }
    }
    ElseIf($ServerStatus -eq "Offline")
    {
        $Script:OfflineServers ++
        ForEach($Service in $Services)
        {
            Write-Host $Target.ServerName `t $ServerStatus -ForegroundColor Red
            Add-Content $report "<tr>"
            Add-Content $report "<td bgcolor= 'Red' align=center>$($Target.Servername)</td>"
            Add-Content $report "<td bgcolor= 'Red' align=center><B>N/A</B></td>"
            Add-Content $report "<td bgcolor= 'Red' align=center>$Service</td>"
            Add-Content $report "<td bgcolor= 'Red' align=center><B>$ServerStatus</B></td>"
            Add-Content $report "</tr>"
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

# Closes the HTML Report
Add-HTML $report "Close" $script:ServerGroup

If($Script:OfflineServers -gt 0)
{
    Write-Host "There were $($Script:OfflineServers) Servers Offline during patching." -ForegroundColor Red
}
If($Script:ServiceErrors -gt 0)
{
    Write-Host ""
    Write-Host "There were $($Script:ServiceErrors) Services that would not start after patching." -ForegroundColor Red
}

Write-Host "Post-Patching Check has completed. Hit any key to proceed to the email prompt."

$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Emails the Report to SYSADMINS@example.com
$email_title = "Send Email?"
$email_message = "Do you want to send the Status Email?"

$email_No = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Doesn't send the email. Select this if you've seen errors and want to rerun the script."

$email_Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Sends the email. Select this if you think patching has completed successfully."

$email_options = [System.Management.Automation.Host.ChoiceDescription[]]($email_No,$email_Yes)

$EmailPrompt = $host.ui.PromptForChoice($email_title, $email_message, $email_options, 1)

Switch ($EmailPrompt)
{
    0{
        Write-Host "No Email Sent."
     }
    1{
        Send-Email $report $Script:ServerGroup
        Write-Host "Email Sent."
     }
}

Write-Host "Script Complete. Press any key to exit ..."

$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Exit