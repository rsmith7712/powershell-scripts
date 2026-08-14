#Requires –Version 3.0
################################
#       Adamj Clean-WSUS       #
#         Version 2.11         #
#                              #
#   The last WSUS Script you   #
#       will ever need!        #
#                              #
#  Taken from various sources  #
#      from the Internet.      #
#                              #
#  Modified By: Adam Marshall  #
#     http://www.adamj.org     #
################################
<#
################################
#         Prerequisites        #
################################

1. This script has to be saved as plain text in ANSI format. If you use Notepad++, you must
   change the encoding to ANSI (Encoding > 'Encode in ANSI' or Encode > 'Convert to ANSI').
   An easy way to tell if it is saved in plain text (ANSI) format is that there is a #Requires
   statement at the top of the script. Make sure that there is a hyphen before the word
   "Version" and you shouldn't have a problem with executing it. If you end up with an error
   like below, it is due to the encoding of the file as you can tell by the â€“ characters
   before the word Version.

   At C:\temp\Clean-WSUS.ps1:1 char:13
   + #Requires â€“Version 3.0

2. You must run this on the WSUS Server itself and any downstream WSUS servers you may have.

3. On the WSUS Server, you must install the SQL Server Management Studio (SSMS) from Microsoft
   so that you have the SQLCMD utility. The SSMS is not a requirement but rather a good tool for
   troubleshooting if needed. The bare minimum requirement is the Microsoft Command Line
   Utilities for SQL Server at whatever version yours is.

4. You must have Powershell 3.0 or higher installed. I recommend version 4.0 or higher.

    Prerequesite Downloads
    ----------------------

    - For Server 2008 SP2:
        - Install Windows Powershell from Server Manager - Features
        - Install .NET 3.5 SP1 from - https://www.microsoft.com/en-ca/download/details.aspx?id=25150
        - Install SQL Server Management Studio from https://www.microsoft.com/en-ca/download/details.aspx?id=30438
          You want to choose SQLManagementStudio_x64_ENU.exe
        - Install .NET 4.0 - https://www.microsoft.com/en-us/download/details.aspx?id=17718
        - Install Powershell 2.0 & WinRM 2.0 from https://www.microsoft.com/en-ca/download/details.aspx?id=20430
        - Install Windows Management Framework 3.0 from https://www.microsoft.com/en-us/download/confirmation.aspx?id=34595

    - For Server 2008 R2:
        - Install .NET 4.5.2 from https://www.microsoft.com/en-ca/download/details.aspx?id=42642
        - Install Windows Management Framework 4.0 and reboot from https://www.microsoft.com/en-ca/download/details.aspx?id=40855
        - Install SQL Server Management Studio from https://www.microsoft.com/en-ca/download/details.aspx?id=30438
          You want to choose SQLManagementStudio_x64_ENU.exe

    - For SBS:
        - This script WILL work on SBS - you must install the pre-requisites above depending on your underlying OS. .NET 4 is
          backwards compatible and I have a lot of users who have installed it on SBS and use the script.

    - For Server 2012 & 2012 R2
        - Install SQL Server Management Studio from https://www.microsoft.com/en-us/download/details.aspx?id=29062
          You want to choose the ENU\x64\SQLManagementStudio_x64_ENU.exe
    
    - For Server 2016
        - I've not personally tested this on server 2016, however many people have run it without issues on Server 2016.
          I don't think Microsoft has changed much between 2012 R2 WSUS and 2016 WSUS.
        - Install SQL Server Management Studio from https://msdn.microsoft.com/library/mt238290.aspx

    IF YOU DON'T WANT TO INSTALL SQL SERVER MANAGEMENT STUDIO:
    Microsoft Command Line Utilities for SQL Server (Minimum requirement instead of SQL Server Management Studio)
        SQL 2008/2008R2 - https://www.microsoft.com/en-ca/download/details.aspx?id=16978
        SQL 2012/2014 - Version 11 - https://www.microsoft.com/en-us/download/details.aspx?id=36433
        SQL 2016 - Version 13 - https://www.microsoft.com/en-us/download/details.aspx?id=53591

################################
#         Instructions         #
################################

 1. Edit the variables below to match your environment.
 2. Open PowerShell using "Run As Administrator" on the WSUS Server.
 3. Because you downloaded this script from the internet, you cannot initially run it directly
    as the ExecutionPolicy is default set to "Restricted" (Server 2008, Server 2008 R2, and
    Server 2012) or "RemoteSigned" (Server 2012 R2).  You must change your ExecutionPolicy to
    Bypass. You can do this with Set-ExecutionPolicy, however that will change it globally for
    the server, which is not recommended. Instead, launch another PowerShell.exe with the
    ExecutionPolicy set to bypass for just that session. At your current PowerShell prompt,
    type in the following and then press enter:

        PowerShell.exe -ExecutionPolicy Bypass

 3. Run the script using -FirstRun.

        .\Clean-WSUS.ps1 -FirstRun

 4. Run the script using -InstallTask to install the Scheduled Task.

        .\Clean-WSUS.ps1 -InstallTask

You can use Get-Help .\Clean-WSUS.ps1 for more information.
#>

<#
.SYNOPSIS
This is the last WSUS Script you will ever need. It cleans up WSUS and runs all the maintenance scripts to keep WSUS running at peak performance.

.DESCRIPTION
################################
#    Background Information    #
#          on Streams          #
################################

All my recommendations are set in -ScheduledRun.

Adamj Remove WSUS Drivers Stream
-----------------------------------------------------

This stream will remove all WSUS Drivers Classifications from the WSUS database.
This has 2 possible running methods - Run through PowerShell, or Run directly in SQL.
The -FirstRun Switch will force the SQL method, but all other automatic runs will use the
PowerShell method. I recommend this be done every quarter.

You can use -RemoveWSUSDriversSQL or -RemoveWSUSDriversPS to run these manually from the command-line.

Adamj Remove Declined WSUS Updates Stream
-----------------------------------------------------

This stream will remove any Declined WSUS updates from the WSUS Database. This is good if you are removing
Specific products (Like Server 2003 / Windows XP updates) from the WSUS server under the Products and
Classifications section. Since this will remove them from the database, if they are still valid,
the next synchronizations will pick up the updates again. I recommend that this be done every quarter.
This stream is NOT included on -FirstRun on purpose.

You can use -RemoveDeclinedWSUSUpdates to run this manually from the command-line.

Adamj Compress Update Revisions Stream
-----------------------------------------------------

This stream will use SQL code to execute pre-existing stored procedures that will return the update id
of each update revision that needs compressing and then compress it. I recommend that this be done
monthly.

You can use -CompressUpdateRevisions to run this manually from the command-line.

Adamj Remove Obsolete Updates Stream
-----------------------------------------------------

This stream will use SQL code to execute pre-existing stored procedures that will return the update id
of each obsolete update in the database and then remove it. There is no magic number of obsolete updates
that will cause the server to time-out. Running this stream can easily take several hours to delete the
updates. While the process is running you might see WSUS synchronization errors. I recommend that this
be done monthly.

You can use -RemoveObsoleteUpdates to run this manually from the command-line.

Adamj WSUS Database Maintenance Stream
-----------------------------------------------------

This stream will perform basic maintenance tasks on SUSDB, the WSUS Database. It will identify indexes
that are fragmented and defragment them. For certain tables, a fill-factor is set in order to improve
insert performance. It will then update potentially out-of-date table statistics. I recommend that this
be done daily.

You can use -WSUSDBMaintenance to run this manually from the command-line.

Adamj Decline Superseded Updates Stream
-----------------------------------------------------

This stream will decline any update that is superseded and not yet declined. This is a BONUS cleanup for
shrinking down the size of your WSUS Server. Any update that has been superseded but has not been declined
is using extra space. This will save you GB of data in your WsusContent folder. I recommend that this be
done every month.

You can use -DeclineSupersededUpdates to run this manually from the command-line.

### Please read the background information below for more details. ###

The Server Cleanup Wizard (SCW) declines superseded updates, only if:

    The newest update is approved, and
    The superseded updates are Not Approved, and
    The superseded update has not been reported as NotInstalled (i.e. Needed) by any computer in the previous 30 days.

There is no feature in the product to automatically decline superseded updates on approval of the newer update,
and in fact, you really do not want that feature. The "Best Practice" in dealing with this situation is:

1. Approve the newer update.
2. Verify that all systems have installed the newer update.
3. Verify that all systems now report the superseded update as Not Applicable.
4. THEN it is safe to decline the superseded update.

To SEARCH for superseded updates, you need only enable the Superseded flag column in the All Updates view, and sort on that column.

There will be four groups:

1. Updates which have never been superseded (blank icon).
2. Updates which have been superseded, but have never superseded another update (icon with blue square at bottom).
3. Updates which have been superseded and have superseded another update (icon with blue square in middle).
4. Updates which have superseded another update (icon with blue square at top).

There's no way to filter based on the approval status of the updates in group #4, but if you've verified that all
necessary/applicable updates in group #4 are approved and installed, then you'd be free to decline groups #2 and #3 en masse.

If you decline superseded updates using the method described:

1. Approve the newer update.
2. Verify that all systems have installed the newer update.
3. Verify that all systems now report the superseded update as Not Applicable.
4. THEN it is safe to decline the superseded update.

### THIS SCRIPT DOES NOT FOLLOW THE ABOVE GUIDELINES. IT WILL JUST DECLINE ANY SUPERSEDED UPDATES. ###

Adamj Clean Up WSUS Synchronization Logs Stream
-----------------------------------------------------

This stream will remove all synchronization logs beyond a specified time period. WSUS is lacking the ability
to remove synchronization logs through the GUI. Your WSUS server will become slower and slower loading up
the synchronization logs view as the synchronization logs will just keep piling up over time. If you have
your synchronization settings set to synchronize 4 times a day, it would take less than 3 months before you
have over 300 logs that it has to load for the view. This is very time consuming and many just ignore this
view and rarely go to it. When they accidentally click on it, they curse. I recommend that this be done daily.

You can use -CleanUpWSUSSynchronizationLogs to run this manually from the command-line.

Adamj Computer Object Cleanup Stream
-----------------------------------------------------

This stream will find all computers that have not syncronized with the server within a certain time period
and remove them. This is usually done through the Server Cleanup Wizard (SCW), however the SCW has been 
hardcoded to 30 days. I've setup this stream to be configurable. You can also tell it not to delete any
computer objects if you really want to. The default I've kept at 30 days. I recommend that this be done daily.

You can use -ComputerObjectCleanup to run this manually from the command-line.

Adamj Server Cleanup Wizard Stream
-----------------------------------------------------

The Server Cleanup Wizard (SCW) is integrated into the WSUS GUI, and can be used to help you manage your
disk space. This runs the SCW through PowerShell which has the added bonus of not timing out as often
the SCW GUI would.

This wizard can do the following things:
    - Remove unused updates and update revisions
      The wizard will remove all older updates and update revisions that have not been approved.

    - Delete computers not contacting the server
      The wizard will delete all client computers that have not contacted the server in thirty days or more.

    - Delete unneeded update files
      The wizard will delete all update files that are not needed by updates or by downstream servers.

    - Decline expired updates
      The wizard will decline all updates that have been expired by Microsoft.

    - Decline superseded updates
      The wizard will decline all updates that meet all the following criteria:
          The superseded update is not mandatory
          The superseded update has been on the server for thirty days or more
          The superseded update is not currently reported as needed by any client
          The superseded update has not been explicitly deployed to a computer group for ninety days or more
          The superseding update must be approved for install to a computer group

I recommend that this be done daily.

You can use -WSUSServerCleanupWizard to run this manually from the command-line.

Adamj Application Pool Memory Configuration Stream
-----------------------------------------------------
Why does the WSUS Application pool crash and how can we fix it? The WSUS Application pool has a
"private memory limit" setting that is configured by default to a low number based on RAM. The
Application pool crashes because it can't keep up and the limit is reached. So why couldn't the WSUS
Application pool keep up? This has to do with the larger number of updates in the Update Catalog
(database) which continues to grow over time. WSUS does not handle an excessive number of updates well
and as as the number increases, the load on the application pool increases causing it to slowly run out
of memory until the limit is hit and WSUS crashes. I've seen it start having issues above the low
number of 10,000 updates and above the high number of 100,000 updates. The number of updates can in
part be due to obsolete updates that remain in the database and it varies in every system and
implementation. In order to help alleviate this, we can increase the memory on the WSUS Application Pool.

I recommend that this be done manually, only if necessary, by the command-line.

-DisplayApplicationPoolMemory to display the current application pool memory.
-IncreaseApplicationPoolMemory <number in MB> to increase the current private memory limit by the number specified.

.NOTES
Name: Clean-WSUS
Author: Adam Marshall
Website: http://www.adamj.org
Donations Accepted: http://www.adamj.org/clean-wsus/donate.html

This script has been tested on Server 2008 SP2, Server 2008 R2, Server 2012, and Server 2012 R2. This script should run
fine on Server 2016 and others have ran it with success on 2016, but I have not had the ability to test it in production.

################################
#      Version History &       #
#        Release Notes         #
################################

Previous Version History - http://www.adamj.org/clean-wsus/release-notes.html

 Version 2.07 to 2.08 (Not Released)
 - Re-adjusted all Write-Host to Write-Output.
 - Changed $AdamjScriptPath from split-path -parent $MyInvocation.MyCommand.Definition to Split-Path $script:MyInvocation.MyCommand.Path.
 - Changed $VerbosePreference to "Continue" when executing -HelpMe.
 - Added Begin, Process, End operators.
 - Setup -HelpMe to change VerbosePreference to continue and change it back at the end to what it was before.
 - Changed Test-Administrator to streamline the process.
 - Changed SQL-Ping-Instance to Test-SQLConnection and cleaned up the code.
 - Added some VERBOSE output throughout the script.
 - Fixed a bug with $ExceptionError in the RemoveDeclinedWSUSUpdatesProceed function.
 - Adjusted the prerequesites and added SQL Cmd line tools requirement with links.
 - Fixed a bug with RemoveDeclinedWSUSUpdates, thanks to Nikolay Semov (Nikolay8159) from the Spiceworks forums.
 - Added regions to each section for ease of modification and readability in PowerShell ISE and other editors.

 Version 2.08 to 2.09 (Not Released)
 - Added CompressUpdateRevisions and RemoveObsoleteUpdates SQL Scripts as MonthlyRun items along with FirstRun.
 - Added Configuration for Mail Report and Save Report options.
 - Added Donation links.
 - Fixed bug with running script from a folder with a space.
 
 Version 2.09 to 2.10 (Not Released)
 - Added the Adamj Application Pool Memory Configuration Stream.
 - Added information about Server 2016 at the prerequisites stage.
 - Added Start-Transcript to -HelpMe stream as now everything is outputted to objects, not just Write-Host.
 - Added Show-MyFunctions and Show-MyVariables and added them to the -HelpMe output instead of the contstraint to just Adamj Variables.
 - Removed the Clean Up Variables section at the end. Once the script finishes running all variables within the script are destroyed
   as none are set globally.
 - Changed $AdamjWSUSServer to auto-populate vs manual entry, along with changing it to lowercase within the script.
 - Added comments for Gmail settings.
 - Added comments in the SQL Server Variable section for the auto-detect issue on Server 2008 (R2).
 - Added an SBS Section to the prerequisites.
 - Created a function for Connect-WSUSServer.
 - Created a function for -InstallTask and a check for powershell version 4 or higher within. Adjusted the Instructions at the top.

 Version 2.10 to 2.11
 - Re-organized Run switches.
 - Added a Restart of the Application pool if you increase the application pool to make sure the settings take effect.
 - Added logic to not connect to the WSUS server if not actually running something that requires it (Display & Increase the
   application pool and InstallTask).
 - Added a configuration value for $AdamjScheduledTaskTime.
 - Added a ComputerObjectCleanup Stream for more control over computer object removals.
 - Cleaned up old commented code and spacing.
 - Added and changed some commented code to verbose output.
 - Removed all the version history except what is different from the last released version and put it on my website instead.

.EXAMPLE
Clean-WSUS -FirstRun
Description: Run the routines that are recommended for running this script for the first time.

.EXAMPLE
Clean-WSUS -InstallTask
Description: Install the Scheduled task to run this script at 8AM daily with the -ScheduledRun switch.

.EXAMPLE
Clean-WSUS -HelpMe
Description: Run the HelpMe stream to create a transcript of the session and provide troubleshooting information in a log file.

.EXAMPLE
Clean-WSUS -DisplayApplicationPoolMemory
Description: Display the current Private Memory Limit for the WSUS Application Pool

.EXAMPLE
Clean-WSUS -IncreaseApplicationPoolMemory 2048
Description: Increase the current Private Memory Limit for the WSUS Application Pool by 2048 MB (2GB)

.EXAMPLE
Clean-WSUS -DailyRun
Description: Run the recommended daily routines.

.EXAMPLE
Clean-WSUS -MonthlyRun
Description: Run the recommended monthly routines.

.EXAMPLE
Clean-WSUS -QuarterlyRun
Description: Run the recommended quarterly routines.

.EXAMPLE
Clean-WSUS -ScheduledRun
Description: Run the recommended routines on a schedule having the script take care of all timetables.

.EXAMPLE
Clean-WSUS -RemoveWSUSDriversSQL -SaveReport TXT
Description: Only Remove WSUS Drivers by way of SQL and save the output as TXT to the script's folder named with the date and time of execution.

.EXAMPLE
Clean-WSUS -RemoveWSUSDriversPS -MailReport HTML
Description: Only Remove WSUS Drivers by way of PowerShell and email the output as HTML to the configured parties.

.EXAMPLE
Clean-WSUS -RemoveDeclinedWSUSUpdates -CleanUpWSUSSynchronizationLogs -WSUSDBMaintenance -WSUSServerCleanupWizard -SaveReport HTML -MailReport TXT
Description: Remove Declined WSUS Updates, Clean Up WSUS Synchronization Logs based on the configuration variables, Run the SQL Maintenance, and run the Server Cleanup Wizard (SCW) and output to an HTML file in the scripts folder named with the date and time of execution, and then email the report in plain text to the configured parties.

.EXAMPLE
Clean-WSUS -DeclineSupersededUpdates -ComputerObjectCleanup -SaveReport TXT -MailReport HTML
Description: Decline superseded updates, computer object cleanup, save the output as TXT to the script's folder, and email the output as HTML to the configured parties.

.EXAMPLE
Clean-WSUS -RemoveObsoleteUpdates -CompressUpdateRevisions -DeclineSupersededUpdates -SaveReport TXT -MailReport HTML
Description: Remove Obsolte Updates, Compress Update Revisions, Decline superseded updates, save the output as TXT to the script's folder, and email the output as HTML to the configured parties.

.LINK
http://www.adamj.org
http://community.spiceworks.com/scripts/show/2998-adamj-wsus-cleanup
http://www.adamj.org/clean-wsus/donate.html
#>
################################
#    Script Setup Parameters   #
#                              #
#  DO NOT EDIT!!! SCROLL DOWN  #
#    TO FIND THE VARIABLES     #
#           TO EDIT            #
################################
[CmdletBinding()]
param (
    # Run the routines that are recommended for running this script for the first time.
    [Switch]$FirstRun,
    # Install the Scheduled Task for daily @ 8AM.
    [Switch]$InstallTask,
    # Run the troubleshooting HelpMe stream to copy and paste for getting support.
    [Switch]$HelpMe,
    # Display the Application Pool Memory Limit
    [switch]$DisplayApplicationPoolMemory,
    # Increase or display the Application Pool Memory Limit.
    [ValidateRange([int]::MinValue,[int]::MaxValue)]
    [Int16]$IncreaseApplicationPoolMemory,
    # Run the recommended daily routines.
    [Switch]$DailyRun,
    # Run the recommended monthly routines.
    [Switch]$MonthlyRun,
    # Run the recommended quarterly routines.
    [Switch]$QuarterlyRun,
    # Run the recommended routines on a schedule having the script take care of all timetables.
    [Switch]$ScheduledRun,
    # Remove WSUS Drivers by way of SQL.
    [Switch]$RemoveWSUSDriversSQL,
    # Remove WSUS Drivers by way of PowerShell.
    [Switch]$RemoveWSUSDriversPS,
    # Compress Update Revisions by way of SQL.
    [Switch]$CompressUpdateRevisions,
    # Remove Obsolete Updates by way of SQL.
    [Switch]$RemoveObsoleteUpdates,
    # Remove Declined WSUS Updates.
    [Switch]$RemoveDeclinedWSUSUpdates,
    # Decline Superseded Updates.
    [Switch]$DeclineSupersededUpdates,
    # Clean Up WSUS Synchronization Logs based on the configuration variables.
    [Switch]$CleanUpWSUSSynchronizationLogs,
    # Clean Up WSUS Synchronization Logs based on the configuration variables.
    [Switch]$ComputerObjectCleanup,
    # Run the SQL Maintenance.
    [Switch]$WSUSDBMaintenance,
    # Run the Server Cleanup Wizard (SCW) through PowerShell rather than through a GUI.
    [Switch]$WSUSServerCleanupWizard,
    # Save the output report to a file named the date and time of execute in the script's folder. TXT or HTML are valid output types.
    [ValidateSet("TXT","HTML")]
    [String]$SaveReport,
    # Email the output report to an email address based on the configuration variables. TXT or HTML are valid output types.
    [ValidateSet("TXT","HTML")]
    [String]$MailReport
    )
Begin {
$AdamjCurrentSystemFunctions = Get-ChildItem function:
$AdamjCurrentSystemVariables = Get-Variable
if (-not $DailyRun -and -not $FirstRun -and -not $MonthlyRun -and -not $QuarterlyRun -and -not $ScheduledRun -and -not $HelpMe -and -not $InstallTask) {
    Write-Verbose "Not using a pre-defined routine"
    if (-not ($DisplayApplicationPoolMemory -or $IncreaseApplicationPoolMemory)) {
        Write-Verbose "Not using a using the Application Pool commands or the InstallTask"
        if ($SaveReport -eq '' -and $MailReport -eq '') {
            Throw "You must use -SaveReport or -MailReport if you are not going to use the pre-defined routines (-FirstRun, -DailyRun, -MonthlyRun, -QuarterlyRun, -ScheduledRun) or the individual switches -HelpMe -DisplayApplicationPoolMemory and -IncreaseApplicationPoolMemory."
        } else { Write-Verbose "SaveReport or MailReport have been specified. Continuing on." }
    } else { Write-Verbose "`$DisplayApplicationPoolMemory -or `$IncreaseApplicationPoolMemory were specified." }
}
if ($HelpMe -eq $True) { $AdamjOldVerbose = $VerbosePreference; $VerbosePreference = "continue"; Start-Transcript -Path "$(get-date -f "yyyy.MM.dd-HH.mm.ss")-HelpMe.txt" }

#region Configuration Variables
################################
#     WSUS Setup Variables     #
################################

# Enter your FQDN of the WSUS server. Example: "$((Get-WmiObject win32_computersystem).DNSHostName).$((Get-WmiObject win32_computersystem).Domain)" or "$((Get-WmiObject win32_computersystem).DNSHostName)" or "server.domain.local"
# WSUS does not play well with Aliases or CNAMEs and requires using the FQDN or the HostName in most cases.
[string]$AdamjWSUSServer = "$((Get-WmiObject win32_computersystem).DNSHostName).$((Get-WmiObject win32_computersystem).Domain)" # This should not be changed unless this doesn't work.

# Use secure connection: $True or $False
[boolean]$AdamjWSUSServerUseSecureConnection = $False

# What port number are you using for WSUS? Example: "80" or "443" if on Server 2008 or "8530" or "8531" if on Server 2012+
[int32]$AdamjWSUSServerPortNumber = "8530"

################################
#  Mail Report Setup Variables #
################################

# From: address for email notifications (it doesn't have to be a real email address, but if you're sending through Gmail it must be
# your Gmail address). Example: "WSUS@example.com" or "user@company.com"
[string]$AdamjMailReportEmailFromAddress = "WSUS@example.com"

# To: address for email notifications. Example: "firstname.lastname@example.com"
[string]$AdamjMailReportEmailToAddress = "firstname.lastname@example.com"

# Subject: of the results email
[string]$AdamjMailReportEmailSubject = "WSUS Cleanup Results"

# Enter your SMTP server name. Example: "mailserver.domain.local" or "mail.example.com" or "smtp.gmail.com"
[string]$AdamjMailReportSMTPServer = "mail.example.com"

# Enter your SMTP port number. Example: "25" or "465" (Usually for SSL) or "587" or "1025"
[int32]$AdamjMailReportSMTPPort = "25"

# Do you want to enable SSL communication for your SMTP Server
[boolean]$AdamjMailReportSMTPServerEnableSSL = $False

# Do you need to authenticate to the server? If not, leave blank.
[string]$AdamjMailReportSMTPServerUsername = ""
[string]$AdamjMailReportSMTPServerPassword = ""

#Note Gmail Settings: smtp.gmail.com Port:587 SSL:Enabled User:user@company.com Password (if you use 2FA, make an app password).

################################
#  Mail Report or Save Report  #
################################

# Do you want to enable the Mail Report for every run?
[boolean]$AdamjMailReport = $False

# Do you want the mailed report to be in HTML or plain text? (Valid options are "HTML" or "TXT")
[string]$AdamjMailReportType = "HTML"

# Do you want to enable the save report for every run? (-FirstRun will save the report regardless)
[boolean]$AdamjSaveReport = $False

# Do you want the saved report to be outputted in HTML or plain text? (Valid options are "HTML" or "TXT")
[string]$AdamjSaveReportType = "TXT"


################################
#  WSUS Server Cleanup Wizard  #
#          Parameters          #
#    Set to $True or $False    #
################################

# Decline updates that have not been approved for 30 days or more, are not currently needed by any clients, and are superseded by an approved update.
[boolean]$AdamjSCWSupersededUpdatesDeclined = $True

# Decline updates that aren't approved and have been expired my Microsoft.
[boolean]$AdamjSCWExpiredUpdatesDeclined = $True

# Delete updates that are expired and have not been approved for 30 days or more.
[boolean]$AdamjSCWObsoleteUpdatesDeleted = $True

# Delete older update revisions that have not been approved for 30 days or more.
[boolean]$AdamjSCWUpdatesCompressed = $True

# Delete computers that have not contacted the server in 30 days or more. Default: $False
# This is taken care of by the Computer Object Cleanup Stream
[boolean]$AdamjSCWObsoleteComputersDeleted = $False

# Delete update files that aren't needed by updates or downstream servers.
[boolean]$AdamjSCWUnneededContentFiles = $True

################################
#   Computer Object Cleanup    #
#          Variables           #
################################

# Do you want to remove the computer objects from WSUS that have not synchronized in days?
# This is good to keep your WSUS clean of previously removed computers.
[boolean]$AdamjComputerObjectCleanup = $False

# If the above is set to $True, how many days of no synchronization do you want to remove
# computer objects from the WSUS Server? Set this to 0 to remove all computer objects.
[int]$AdamjComputerObjectCleanupSearchDays = "180"

################################
#   Scheduled Run Variables    #
################################

# On what day do you wish to run the MonthlyRun and QuarterlyRun Stream? I recommend on the 1st-7th of the month.
# This will give enough time for you to approve (if you approve manually) and your computers to receive the
# superseding updates after patch Tuesday (second Tuesday of the month).
# (Valid days are 1-31. February, April, June, September, and November have logic to set to the last day
# of the month if this is set to a number greater than the amount of days in that month, including leap years.)
[int]$AdamjScheduledRunStreamsDay = "7"

# What months would you like to run the QuarterlyRun Stream?
# (Valid months are 1-12, comma separated for multiple months)
[string]$AdamjScheduledRunQuarterlyMonths = "1,4,7,10"

# What time daily do you want to run the script using the scheduled task?
[string]$AdamjScheduledTaskTime = "7:00am"

################################
#        Clean Up WSUS         #
#     Synchronization Logs     #
#           Variables          #
################################

# Clean up the synchronization logs older than a consistency.

# (Valid consistency number are whole numbers.)
[int]$AdamjCleanUpWSUSSynchronizationLogsConsistencyNumber = "14"

# Valid consistency time are "Day" or "Month"
[String]$AdamjCleanUpWSUSSynchronizationLogsConsistencyTime = "Day"

# Or remove all synchronization logs each time
[boolean]$AdamjCleanUpWSUSSynchronizationLogsAll = $False

################################
#     SQL Server Variable      #
################################

# ONLY uncomment and fill out if you are using a dedicated SQL Instance or if the script tells you to
# otherwise leave this commented for auto-detection of the proper SQL Instance for the Windows Internal Database.
# Example: "SERVER\INSTANCE" or "SERVER" (if using the Default Instance)

# If you are using a Remote SQL connection, you will need to set the Scheduled Task to use the computer account
# as the user that runs the script (Instead of searching for it, you must type it in the format of: DOMAIN\COMPUTER$)
# or run the Scheduled Task as a user account saving credentials so that it can pass them through to the SQL Server.

# If you are having issues with the auto-dection on Server 2008 (R2), it may be due to the timeout for testing of the
# connection to the server. In this case, please specify this as 'np:\\.\pipe\...\query' as this
# will increase the timeout to 60 seconds and it should connect within that time.

#[string]$AdamjSQLServer = ''

################################
# Do not edit below this line  #
################################
}
#endregion

Process {
$AdamjScriptTime = Get-Date
$AdamjWSUSServer = $AdamjWSUSServer.ToLower()
Write-verbose "Set the script's current working directory path"
$AdamjScriptPath = Split-Path $script:MyInvocation.MyCommand.Path
Write-Verbose "`$AdamjScriptPath = $AdamjScriptPath"

#region Test Elevation
function Test-Administrator
{
    $CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $CurrentUser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}
Write-Verbose "Testing to see if you are running this from an Elevated PowerShell Prompt."
if ((Test-Administrator) -ne $True) {
    Throw "ERROR: You must run this from an Elevated PowerShell Prompt on each WSUS Server in your environment. If this is done through scheduled tasks, you must check the box `"Run with the highest privileges`""
}
else {
    Write-Verbose "Done. You are running this from an Elevated PowerShell Prompt"
}
#endregion Test Elevation

if ($HelpMe -eq $True) {
    $Script:HelpMeHeader = @"
=============================
  Clean-WSUS HelpMe Stream
=============================

This is the HelpMe Section for troubleshooting
Please provide this information to get support



"@
$Script:HelpMeHeader
}

#region Test SQLConnection
function Test-SQLConnection
{
    param (
        [parameter(Mandatory = $true)][string] $ServerInstance,
        [parameter(Mandatory = $false)][int] $TimeOut = 1
    )

    $SqlConnectionResult = $false

    try
    {
        $SqlCatalog = "SUSDB"
        $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
        $SqlConnection.ConnectionString = "Server = $ServerInstance; Database = $SqlCatalog; Integrated Security = True; Connection Timeout=$TimeOut"
        $TimeOutVerbage = if ($TimeOut -gt "1") { "seconds" } else { "second" }
        Write-Verbose "Initiating SQL Connection Testing to $ServerInstance with a timeout of $TimeOut $TimeOutVerbage"
        $SqlConnection.Open()
        Write-Verbose "Connected. Setting `$SqlConnectionResult to $($SqlConnection.State -eq "Open")"
        $SqlConnectionResult = $SqlConnection.State -eq "Open"
    }

    catch
    {
        Write-Output "Connection Failed."
    }

    finally
    {
        $SqlConnection.Close()
    }

    return $SqlConnectionResult
}

[string]$AdamjWID2008 = 'np:\\.\pipe\...\query'
[string]$AdamjWID2012 = 'np:\\.\pipe\...\query'
if (-not [string]::isnullorempty($AdamJSQLServer)) {
    Write-Verbose "Test to see if $AdamjSQLServer is set and if it is, with something other than blank. Then test to see if it can connect."
    if ((Test-SQLConnection $AdamjSQLServer 60) -eq $False) {
        # If it doesn't work, terminate the script erroring out with a reason.
        Throw "I've tested the server `"$AdamjSQLServer`" in the configuration but can't connect to that SQL Server Instance. Please check the spelling again. Don't forget to specify the SQL Instance if there is one."
        }
} elseif ((Test-SQLConnection $AdamjWID2008) -eq $true) {
    Write-Verbose "Setting `$AdamjSQLServer for server 2008 & 2008 R2 Windows Internal Database"
    $AdamjSQLServer = $AdamjWID2008
} elseif ((Test-SQLConnection $AdamjWID2012) -eq $true) {
    Write-Verbose "Setting `$AdamjSQLServer for server 2012 & 2012 R2 Windows Internal Database"
    $AdamjSQLServer = $AdamjWID2012
} else {
    if ($HelpMe -ne $True) {
        #Terminate the script erroring out with a reason.
        Throw "I can't determine the SQL Server Instance. Please find the `"`$AdamjSQLServer`" variable in the configuration and set it as your SERVER\INSTANCE for WSUS"
    }
    else { Write-Output "I can't connect to SQL, and you've asked for help. Connecting to the WSUS Server to get troubleshooting information." }
}

#Create the connection command variable.
$AdamjSQLConnectCommand = "sqlcmd -S $AdamjSQLServer"
#endregion Test SQLConnection

#region Connect to the WSUS Server
function Connect-WSUSServer {
    [CmdletBinding()]
    param 
    (
        [Parameter(Position=0, Mandatory = $True)]
        [Alias("Server")]
        [string]$WSUSServer,
        
        [Parameter(Position=1, Mandatory = $True)]
        [Alias("Port")]
        [int]$WSUSPort,
                
        [Parameter(Position=2, Mandatory = $True)]
        [Alias("SSL")]
        [boolean]$WSUSEnableSSL
    )
    Write-Verbose "Load .NET assembly"
    [void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration");

    Write-Verbose "Connect to WSUS Server: $WSUSServer"
    $Script:WSUSAdminProxy     = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($WSUSServer,$WSUSEnableSSL,$WSUSPort);
    If ($? -eq $False) { 
        Throw "ERROR Connecting to the WSUS Server: $WSUSServer. Please check your settings and try again."
    } else {
            $Script:AdamjConnectedTime = Get-Date
            $Script:AdamjConnectedTXT = "Connected to the WSUS server $AdamjWSUSServer @ $($AdamjConnectedTime.ToString(`"yyyy.MM.dd hh:mm:ss tt zzz`"))`r`n`r`n"
            $Script:AdamjConnectedHTML = "<i>Connected to the WSUS server $AdamjWSUSServer @ $($AdamjConnectedTime.ToString(`"yyyy.MM.dd hh:mm:ss tt zzz`"))</i>`r`n`r`n"
    	    Write-Output "Connected to the WSUS server $AdamjWSUSServer"
    }
}

if (($InstallTask -or $DisplayApplicationPoolMemory -or $IncreaseApplicationPoolMemory) -eq $False) {
    Connect-WSUSServer -Server $AdamjWSUSServer -Port $AdamjWSUSServerPortNumber -SSL $AdamjWSUSServerUseSecureConnection
    $AdamjWSUSServerAdminProxy = $Script:WSUSAdminProxy
}
#endregion Connect to the WSUS Server

#region Get-DiskFree Function
################################
#         Get-DiskFree         #
################################

function Get-DiskFree
# Taken from http://binarynature.blogspot.ca/2010/04/powershell-version-of-df-command.html
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Position=0,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('hostname')]
        [Alias('cn')]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Position=1,
                   Mandatory=$false)]
        [Alias('runas')]
        [System.Management.Automation.Credential()]$Credential =
        [System.Management.Automation.PSCredential]::Empty,

        [Parameter(Position=2)]
        [switch]$Format
    )

    BEGIN
    {
        function Format-HumanReadable
        {
            param ($size)
            switch ($size)
            {
                {$_ -ge 1PB}{"{0:#.#'P'}" -f ($size / 1PB); break}
                {$_ -ge 1TB}{"{0:#.#'T'}" -f ($size / 1TB); break}
                {$_ -ge 1GB}{"{0:#.#'G'}" -f ($size / 1GB); break}
                {$_ -ge 1MB}{"{0:#.#'M'}" -f ($size / 1MB); break}
                {$_ -ge 1KB}{"{0:#'K'}" -f ($size / 1KB); break}
                default {"{0}" -f ($size) + "B"}
            }
        }
        $wmiq = 'SELECT * FROM Win32_LogicalDisk WHERE Size != Null AND DriveType >= 2'
    }

    PROCESS
    {
        foreach ($computer in $ComputerName)
        {
            try
            {
                if ($computer -eq $env:COMPUTERNAME)
                {
                    $disks = Get-WmiObject -Query $wmiq `
                             -ComputerName $computer -ErrorAction Stop
                }
                else
                {
                    $disks = Get-WmiObject -Query $wmiq `
                             -ComputerName $computer -Credential $Credential `
                             -ErrorAction Stop
                }

                if ($Format)
                {
                    # Create array for $disk objects and then populate
                    $diskarray = @()
                    $disks | ForEach-Object { $diskarray += $_ }

                    $diskarray | Select-Object @{n='Name';e={$_.SystemName}},
                        @{n='Vol';e={$_.DeviceID}},
                        @{n='Size';e={Format-HumanReadable $_.Size}},
                        @{n='Used';e={Format-HumanReadable `
                        (($_.Size)-($_.FreeSpace))}},
                        @{n='Avail';e={Format-HumanReadable $_.FreeSpace}},
                        @{n='Use%';e={[int](((($_.Size)-($_.FreeSpace))`
                        /($_.Size) * 100))}},
                        @{n='FS';e={$_.FileSystem}},
                        @{n='Type';e={$_.Description}}
                }
                else
                {
                    foreach ($disk in $disks)
                    {
                        $diskprops = @{'Volume'=$disk.DeviceID;
                                   'Size'=$disk.Size;
                                   'Used'=($disk.Size - $disk.FreeSpace);
                                   'Available'=$disk.FreeSpace;
                                   'FileSystem'=$disk.FileSystem;
                                   'Type'=$disk.Description
                                   'Computer'=$disk.SystemName;}

                        # Create custom PS object and apply type
                        $diskobj = New-Object -TypeName PSObject `
                                   -Property $diskprops
                        $diskobj.PSObject.TypeNames.Insert(0,'BinaryNature.DiskFree')

                        Write-Output $diskobj
                    }
                }
            }
            catch 
            {
                # Check for common DCOM errors and display "friendly" output
                switch ($_)
                {
                    { $_.Exception.ErrorCode -eq 0x800706ba } `
                        { $err = 'Unavailable (Host Offline or Firewall)';
                            break; }
                    { $_.CategoryInfo.Reason -eq 'UnauthorizedAccessException' } `
                        { $err = 'Access denied (Check User Permissions)';
                            break; }
                    default { $err = $_.Exception.Message }
                }
                Write-Warning "$computer - $err"
            }
        }
    }
    
    END {}
}
#endregion Get-DiskFree Function

#region Setup The Header
################################
#       Setup the Header       #
################################

function CreateAdamjHeader {
$Script:AdamjBodyHeaderTXT = @"
################################
#                              #
#       Adamj Clean-WSUS       #
#         Version 2.11         #
#                              #
#   The last WSUS Script you   #
#        will ever need!       #
#                              #
################################


"@
$Script:AdamjBodyHeaderHTML = @"
    <table style="height: 0px; width: 0px;" border="0">
	    <tbody>
		    <tr>
			    <td colspan="3">
				    <span
						    style="font-family: tahoma,arial,helvetica,sans-serif;">################################</span>
			    </td>
		    </tr>
		    <tr>
			    <td style="text-align: left;">#</td>
			    <td style="text-align: center;">&nbsp;</td>
			    <td style="text-align: right;">#</td>
		    </tr>
		    <tr>
			    <td style="text-align: left;">#</td>
			    <td style="text-align: center;"><span style="font-family: tahoma,arial,helvetica,sans-serif;">Adamj Clean-WSUS</span></td>
			    <td style="text-align: right;">#</td>
		    </tr>
		    <tr>
			    <td style="text-align: left;">#</td>
			    <td style="text-align: center;"><span style="font-family: tahoma,arial,helvetica,sans-serif;">Version 2.11</span></td>
			    <td style="text-align: right;">#</td>
		    </tr>
		    <tr>
			    <td style="text-align: left;">#</td>
			    <td>&nbsp;</td>
			    <td style="text-align: right;">#</td>
		    </tr>
		    <tr>
			    <td style="text-align: left;">#</td>
			    <td style="text-align: center;"><span style="font-family: tahoma,arial,helvetica,sans-serif;">The last WSUS Script you</span></td>
			    <td style="text-align: right;">#</td>
		    </tr>
		    <tr>
			    <td style="text-align: left;">#</td>
			    <td style="text-align: center;"><span style="font-family: tahoma,arial,helvetica,sans-serif;">will ever need!</span></td>
			    <td style="text-align: right;">#</td>
		    </tr>
		    <tr>
			    <td style="text-align: left;">#</td>
			    <td>&nbsp;</td>
			    <td style="text-align: right;">#</td>
		    </tr>
		    <tr>
			    <td colspan="3"><span style="font-family: tahoma,arial,helvetica,sans-serif;">################################</span></td>
		    </tr>
	    </tbody>
    </table>
"@
}
#endregion Setup The Header

#region Setup The Footer
################################
#       Setup the Footer       #
################################

function CreateAdamjFooter {
$Script:AdamjBodyFooterTXT = @"

################################
#    End of the WSUS Cleanup   #
################################
#                              #
#         Adam Marshall        #
#     http://www.adamj.org     #
#      Donations Accepted      #
#                              #
#   Latest version available   #
#        from Spiceworks       #
#                              #
################################

http://community.spiceworks.com/scripts/show/2998-adamj-clean-wsus
Donations Accepted: http://www.adamj.org/clean-wsus/donate.html
"@
$Script:AdamjBodyFooterHTML = @"
    <table style="height: 0px; width: 0px;" border="0">
      <tbody>
        <tr>
          <td colspan="3"><span style="font-family: tahoma,arial,helvetica,sans-serif;">################################</span></td>
        </tr>
        <tr>
          <td style="text-align: left;">#</td>
          <td style="text-align: center;"><span style="font-family: tahoma,arial,helvetica,sans-serif;">End of the WSUS Cleanup</span></td>
          <td style="text-align: right;">#</td>
        </tr>
        <tr>
          <td colspan="3" rowspan="1"><span style="font-family: tahoma,arial,helvetica,sans-serif;">################################</span></td>
        </tr>
        <tr>
          <td style="text-align: left;">#</td>
          <td style="text-align: center;">&nbsp;</td>
          <td style="text-align: right;">#</td>
        </tr>
        <tr>
          <td style="text-align: left;">#</td>
          <td style="text-align: center;"><span style="font-family: tahoma,arial,helvetica,sans-serif;">Adam Marshall</span></td>
          <td style="text-align: right;">#</td>
        </tr>
        <tr>
          <td style="text-align: left;">#</td>
          <td style="text-align: center;"><span style="font-family: tahoma,arial,helvetica,sans-serif;">http://www.adamj.org</span></td>
          <td style="text-align: right;">#</td>
        </tr>
        <tr>
          <td style="text-align: left;">#</td>
          <td style="text-align: center;"><a href="http://www.adamj.org/clean-wsus/donate.html"><span style="font-family: tahoma,arial,helvetica,sans-serif;">Donations Accepted</span></a></td>
          <td style="text-align: right;">#</td>
        </tr>
        <tr>
          <td style="text-align: left;">#</td>
          <td>&nbsp;</td>
          <td style="text-align: right;">#</td>
        </tr>
        <tr>
          <td style="text-align: left;">#</td>
          <td style="text-align: center;"><span style="font-family: tahoma,arial,helvetica,sans-serif;">Latest version available</span></td>
          <td style="text-align: right;">#</td>
        </tr>
        <tr>
          <td style="text-align: left;">#</td>
          <td style="text-align: center;"><a href="http://community.spiceworks.com/scripts/show/2998-adamj-clean-wsus"><span style="font-family: tahoma,arial,helvetica,sans-serif;">from Spiceworks</span></a></td>
          <td style="text-align: right;">#</td>
        </tr>
        <tr>
          <td style="text-align: left;">#</td>
          <td>&nbsp;</td>
          <td style="text-align: right;">#</td>
        </tr>
        <tr>
          <td colspan="3"><span style="font-family: tahoma,arial,helvetica,sans-serif;">################################</span></td>
        </tr>
      </tbody>
    </table>
"@
}
#endregion Setup The Footer

#region Show-My Functions
################################
#   Show-My Functions Stream   #
################################

function Show-MyFunctions { Get-ChildItem function: | Where-Object { $AdamjCurrentSystemFunctions -notcontains $_ } | Format-Table -AutoSize -Property CommandType,Name }
function Show-MyVariables { Get-Variable | Where-Object { $AdamjCurrentSystemVariables -notcontains $_ } | Format-Table }
#endregion Show-My Functions

#region Install-Task Function
################################
#  Install-Task Configuration  #
################################

Function Install-Task {
    $Windows = [PSCustomObject]@{
        Caption = (Get-WmiObject -Class Win32_OperatingSystem).Caption
        Version = [Environment]::OSVersion.Version
    }
    if ($Windows.Version.Major -gt "6") { Write-Verbose "$($Windows.Caption) - Use Win8 Compatibility" ; $Compatibility = "Win8" }
    if ($Windows.Version.Major -ge "6" -and $Windows.Version.Minor -ge "2" ) { Write-Verbose "$($Windows.Caption) - Use Win8 Compatibility" ; $Compatibility = "Win8" }
    if ($Windows.Version.Major -ge "6" -and $Windows.Version.Minor -eq "1" ) { Write-Verbose "$($Windows.Caption) - Use Win7 Compatibility" ; $Compatibility = "Win7" }
    if ($Windows.Version.Major -ge "6" -and $Windows.Version.Minor -eq "0" ) { Write-Verbose "$($Windows.Caption) - Use Vista Compatibility" ; $Compatibility = "Vista" }

    $Trigger = New-ScheduledTaskTrigger -At $AdamjScheduledTaskTime -Daily #Trigger the task daily at $AdamjScheduledTaskTime
    $User = "$env:USERDOMAIN\$env:USERNAME"
    $Principal = New-ScheduledTaskPrincipal -UserID "$env:USERDOMAIN\$env:USERNAME" -LogonType S4U -RunLevel Highest
    $TaskName = "Adamj Clean-WSUS"
    $Description = "This task will run the Adamj Clean-WSUS script with the -ScheduledRun parameter which takes care of everything for you according to my recommendations."
    $Action = New-ScheduledTaskAction -Execute "$((Get-Command powershell.exe).Definition)" -Argument "-ExecutionPolicy Bypass `"$($script:MyInvocation.MyCommand.Path) -ScheduledRun`""
    $Settings = New-ScheduledTaskSettingsSet -Compatibility $Compatibility
    Write-Verbose "Register the Scheduled task."
    Register-ScheduledTask -TaskName $TaskName -Description $Description -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Force
}
$PowerShellMajorVersion = $($PSVersionTable.PSVersion.Major)
Write-Verbose "`$InstallTask is $InstallTask"
if ($InstallTask -eq $True) {
    $Version = @{}
    $Version.Add("Major", ((Get-CimInstance Win32_OperatingSystem).Version).Split(".")[0])
    $Version.Add("Minor", ((Get-CimInstance Win32_OperatingSystem).Version).Split(".")[1])
    #$Version.Add("Major", "5")
    #$Version.Add("Minor", "3")
    if ([int]$Version.Get_Item("Major") -ge "7" -or ([int]$Version.Get_Item("Major") -ge "6" -and [int]$Version.Get_Item("Minor") -ge "2")) {
        Write-Verbose "YES - OS Version $([int]$Version.Get_Item("Major")).$([int]$Version.Get_Item("Minor"))"
        Install-Task
    } else {
        Write-Verbose "NO - OS Version $([int]$Version.Get_Item("Major")).$([int]$Version.Get_Item("Minor"))"
        Write-Output ""
        Write-Output "You are not using Windows Server 2012 or higher. You will have to manually create the Scheduled Task"
        Write-Output ""
        $AdamjManuallyCreateTaskInstructions = @"
To Create a Scheduled Task:

 1. Open Task Scheduler and Create a new task (not a basic task)
 2. Go to the General Tab:
 3. Name: "Adamj Clean-WSUS"
 4. Under the section "Security Options" put the dot in "Run whether the user is logged on or not"
 5. Check "Do not store password. The task will only have access to local computer resources"
 6. Check "Run with highest privileges."
 7. Under the section "Configure for" - Choose the OS of the Server (e.g. Server 2012 R2)
 8. Go to the Triggers Tab:
 9. Click New at the bottom left.
10. Under the section "Settings"
11. Choose Daily. Choose $AdamjScheduledTaskTime
12. Confirm Enabled is checked, Press OK.
13. Go to the Actions Tab:
14. Click New at the bottom left.
15. Action should be "Start a program"
16. The "Program/script" should be set to
        
        $((Get-Command powershell.exe).Definition)

17. The arguments line should be set to 

        -ExecutionPolicy Bypass `"$($script:MyInvocation.MyCommand.Path) -ScheduledRun`"

18. Go to the Settings Tab:
19. Check "Allow task to be run on demand"
20. Click OK
"@
    Write-Output $AdamjManuallyCreateTaskInstructions
    }
}
#endregion Install-Task Function

#region ApplicationPoolMemory Function
################################
#   Application Pool Memory    #
#     Configuration Stream     #
################################
function ApplicationPoolMemory {
    Param(
    [ValidateRange([int]::MinValue,[int]::MaxValue)]
    [Int]$IncreaseApplicationPoolBy
    )
    $DateNow = Get-Date
    Import-Module WebAdministration
    $applicationPoolsPath = "/system.applicationHost/applicationPools"
    $applicationPools = Get-WebConfiguration $applicationPoolsPath
    foreach ($appPool in $applicationPools.Collection) {
	    if ($appPool.name -eq 'WsusPool') {
		    $appPoolPath = "$applicationPoolsPath/add[@name='$($appPool.Name)']"
		    $CurrentPrivateMemory = (Get-WebConfiguration "$appPoolPath/recycling/periodicRestart/@privateMemory").Value
            Write-Output "Current Private Memory Limit for $($appPool.name) is: $($CurrentPrivateMemory/1000) MB"
            if ($IncreaseApplicationPoolBy) {
                $IncreaseApplicationPoolBy=$IncreaseApplicationPoolBy * 1000
                $NewPrivateMemory = $CurrentPrivateMemory + $IncreaseApplicationPoolBy
                Write-Output "New Private Memory Limit for $($appPool.name) is: $($NewPrivateMemory/1000) MB"
                Set-WebConfiguration "$appPoolPath/recycling/periodicRestart/@privateMemory" -Value $NewPrivateMemory
                Write-Verbose "Restart the $($appPool.name) Application Pool to make the new settings take effect"
                Restart-WebAppPool -Name $($appPool.name)
            }
	    }
    }
    $FinishedRunning = Get-Date
    $DifferenceInTime = New-TimeSpan –Start $DateNow –End $FinishedRunning
    $Duration = "{0:00}:{1:00}:{2:00}:{3:00}:{4:00}" -f ($DifferenceInTime | % {$_.Days, $_.Hours, $_.Minutes, $_.Seconds, $_.Milliseconds})
    Write-Verbose "Application Pool Memory Stream Duration: $Duration"
}
#endregion ApplicationPoolMemory Function

#region RemoveWSUSDrivers Function
################################
#   Adamj Remove WSUS Drivers  #
#           Stream             #
################################

function RemoveWSUSDrivers {
    param (
        [Parameter()]
        [Switch] $SQL
    )
    function RemoveWSUSDriversSQL {
        $AdamjRemoveWSUSDriversSQLScript = @"
/*
################################
#   Adamj WSUS Delete Drivers  #
#         SQL Script           #
#       Version 1.0            #
#  Taken from various sources  #
#      from the Internet.      #
#                              #
#  Modified By: Adam Marshall  #
#     http://www.adamj.org     #
################################

-- Originally taken from http://www.flexecom.com/how-to-delete-driver-updates-from-wsus-3-0/
-- Modified to be dynamic and more of a nice output
*/
USE SUSDB;
GO

SET NOCOUNT ON;
DECLARE @tbrevisionlanguage nvarchar(255)
DECLARE @tbProperty nvarchar(255)
DECLARE @tbLocalizedPropertyForRevision nvarchar(255)
DECLARE @tbFileForRevision nvarchar(255)
DECLARE @tbInstalledUpdateSufficientForPrerequisite nvarchar(255)
DECLARE @tbPreRequisite nvarchar(255)
DECLARE @tbDeployment nvarchar(255)
DECLARE @tbXml nvarchar(255)
DECLARE @tbPreComputedLocalizedProperty nvarchar(255)
DECLARE @tbDriver nvarchar(255)
DECLARE @tbFlattenedRevisionInCategory nvarchar(255)
DECLARE @tbRevisionInCategory nvarchar(255)
DECLARE @tbMoreInfoURLForRevision nvarchar(255)
DECLARE @tbRevision nvarchar(255)
DECLARE @tbUpdateSummaryForAllComputers nvarchar(255)
DECLARE @tbUpdate nvarchar(255)
DECLARE @var1 nvarchar(255)

/*
This query gives you the GUID that you will need to substitute in all subsequent queries. In my case, it is
D2CB599A-FA9F-4AE9-B346-94AD54EE0629. I saw this GUID in several WSUS databases so I think it does not change;
at least not between WSUS 3.0 SP2 servers. Either way, we are setting a variable for this so this will
dynamically reference the correct GUID.
*/

SELECT @var1 = UpdateTypeID FROM tbUpdateType WHERE Name = 'Driver'

/*
The bad news is that WSUS database has over 100 tables. The good news is that SQL allows to enforce referential
integrity in data model designs, which in this case can be used to essentially reverse engineer a procedure,
that as far as I know isn’t documented anywhere.

The trick is to delete all driver type records from tbUpdate table – but FIRST we have to delete all records in
all other tables (revisions, languages, dependencies, files, reports…), which refer to driver rows in tbUpdate.

Here’s how this is done, in 16 tables/queries.
*/

delete from tbrevisionlanguage where revisionid in (select revisionid from tbRevision where LocalUpdateId in (select LocalUpdateId from tbUpdate where UpdateTypeID = @var1))
SELECT @tbrevisionlanguage = @@ROWCOUNT
PRINT 'Delete records from tbrevisionlanguage: ' + @tbrevisionlanguage

delete from tbProperty where revisionid in (select revisionid from tbRevision where LocalUpdateId in (select LocalUpdateId from tbUpdate where UpdateTypeID = @var1))
SELECT @tbProperty = @@ROWCOUNT
PRINT 'Delete records from tbProperty: ' + @tbProperty

delete from tbLocalizedPropertyForRevision where revisionid in (select revisionid from tbRevision where LocalUpdateId in (select LocalUpdateId from tbUpdate where UpdateTypeID = @var1))
SELECT @tbLocalizedPropertyForRevision = @@ROWCOUNT
PRINT 'Delete records from tbLocalizedPropertyForRevision: ' + @tbLocalizedPropertyForRevision

delete from tbFileForRevision where revisionid in (select revisionid from tbRevision where LocalUpdateId in (select LocalUpdateId from tbUpdate where UpdateTypeID = @var1))
SELECT @tbFileForRevision = @@ROWCOUNT
PRINT 'Delete records from tbFileForRevision: ' + @tbFileForRevision

delete from tbInstalledUpdateSufficientForPrerequisite where prerequisiteid in (select Prerequisiteid from tbPreRequisite where revisionid in (select revisionid from tbRevision where LocalUpdateId in (select LocalUpdateId from tbUpdate where UpdateTypeID = @var1)))
SELECT @tbInstalledUpdateSufficientForPrerequisite = @@ROWCOUNT
PRINT 'Delete records from tbInstalledUpdateSufficientForPrerequisite: ' + @tbInstalledUpdateSufficientForPrerequisite

delete from tbPreRequisite where revisionid in (select revisionid from tbRevision where LocalUpdateId in (select LocalUpdateId from tbUpdate where UpdateTypeID = @var1))
SELECT @tbPreRequisite = @@ROWCOUNT
PRINT 'Delete records from tbPreRequisite: ' + @tbPreRequisite

delete from tbDeployment where revisionid in (select revisionid from tbRevision where LocalUpdateId in (select LocalUpdateId from tbUpdate where UpdateTypeID = @var1))
SELECT @tbDeployment = @@ROWCOUNT
PRINT 'Delete records from tbDeployment: ' + @tbDeployment

delete from tbXml where revisionid in (select revisionid from tbRevision where LocalUpdateId in (select LocalUpdateId from tbUpdate where UpdateTypeID = @var1))
SELECT @tbXml = @@ROWCOUNT
PRINT 'Delete records from tbXml: ' + @tbXml

delete from tbPreComputedLocalizedProperty where revisionid in (select revisionid from tbRevision where LocalUpdateId in (select LocalUpdateId from tbUpdate where UpdateTypeID = @var1))
SELECT @tbPreComputedLocalizedProperty = @@ROWCOUNT
PRINT 'Delete records from tbPreComputedLocalizedProperty: ' + @tbPreComputedLocalizedProperty

delete from tbDriver where revisionid in (select revisionid from tbRevision where LocalUpdateId in (select LocalUpdateId from tbUpdate where UpdateTypeID = @var1))
SELECT @tbDriver = @@ROWCOUNT
PRINT 'Delete records from tbDriver: ' + @tbDriver

delete from tbFlattenedRevisionInCategory where revisionid in (select revisionid from tbRevision where LocalUpdateId in (select LocalUpdateId from tbUpdate where UpdateTypeID = @var1))
SELECT @tbFlattenedRevisionInCategory = @@ROWCOUNT
PRINT 'Delete records from tbFlattenedRevisionInCategory: ' + @tbFlattenedRevisionInCategory

delete from tbRevisionInCategory where revisionid in (select revisionid from tbRevision where LocalUpdateId in (select LocalUpdateId from tbUpdate where UpdateTypeID = @var1))
SELECT @tbRevisionInCategory = @@ROWCOUNT
PRINT 'Delete records from tbRevisionInCategory: ' + @tbRevisionInCategory

delete from tbMoreInfoURLForRevision where revisionid in (select revisionid from tbRevision where LocalUpdateId in (select LocalUpdateId from tbUpdate where UpdateTypeID = @var1))
SELECT @tbMoreInfoURLForRevision = @@ROWCOUNT
PRINT 'Delete records from tbMoreInfoURLForRevision: ' + @tbMoreInfoURLForRevision

delete from tbRevision where LocalUpdateId in (select LocalUpdateId from tbUpdate where UpdateTypeID = @var1)
SELECT @tbRevision = @@ROWCOUNT
PRINT 'Delete records from tbRevision: ' + @tbRevision

delete from tbUpdateSummaryForAllComputers where LocalUpdateId in (select LocalUpdateId from tbUpdate where UpdateTypeID = @var1)
SELECT @tbUpdateSummaryForAllComputers = @@ROWCOUNT
PRINT 'Delete records from tbUpdateSummaryForAllComputers: ' + @tbUpdateSummaryForAllComputers

PRINT CHAR(13)+CHAR(10) + 'This is the last query and this is really what we came here for.'

delete from tbUpdate where UpdateTypeID = @var1
SELECT @tbUpdate = @@ROWCOUNT
PRINT 'Delete records from tbUpdate: ' + @tbUpdate

/*
If at this point you get an error saying something about foreign key constraint, that will be most likely
due to the difference between which reports I ran in my WSUS installation and which reports were ran against
your particular installation. Fortunately, the error gives you exact location (table) where this constraint
is violated, so you can adjust one of the queries in the batch above to delete references in any other tables.
*/
"@
        Write-Verbose "Create a file with the content of the RemoveWSUSDrivers Script above in the same working directory as this PowerShell script is running."
        $AdamjRemoveWSUSDriversSQLScriptFile = "$AdamjScriptPath\AdamjRemoveWSUSDrivers.sql"
        $AdamjRemoveWSUSDriversSQLScript | Out-File "$AdamjRemoveWSUSDriversSQLScriptFile"
        # Re-jig the $AdamjSQLConnectCommand to replace the $ with a `$ for Windows 2008 Internal Database possiblity.
        $AdamjSQLConnectCommand = $AdamjSQLConnectCommand.Replace('$','`$')
        Write-Verbose "Execute the SQL Script and store the results in a variable."
        $AdamjRemoveWSUSDriversSQLScriptJobCommand = [scriptblock]::create("$AdamjSQLConnectCommand -i `"$AdamjRemoveWSUSDriversSQLScriptFile`" -I")
        Write-Verbose "`$AdamjRemoveWSUSDriversSQLScriptJobCommand = $AdamjRemoveWSUSDriversSQLScriptJobCommand"
        $AdamjRemoveWSUSDriversSQLScriptJob = Start-Job -ScriptBlock $AdamjRemoveWSUSDriversSQLScriptJobCommand
        Wait-Job $AdamjRemoveWSUSDriversSQLScriptJob
        $AdamjRemoveWSUSDriversSQLScriptJobOutput = Receive-Job $AdamjRemoveWSUSDriversSQLScriptJob
        Remove-Job $AdamjRemoveWSUSDriversSQLScriptJob
        Write-Verbose "Remove the SQL Script file."
        Remove-Item "$AdamjRemoveWSUSDriversSQLScriptFile"
        $Script:AdamjRemoveWSUSDriversSQLOutputTXT = $AdamjRemoveWSUSDriversSQLScriptJobOutput.Trim() -creplace'(?m)^\s*\r?\n','' -creplace '$?',"" -creplace "$","`r`n`r`n"
        $Script:AdamjRemoveWSUSDriversSQLOutputHTML = $AdamjRemoveWSUSDriversSQLScriptJobOutput.Trim() -creplace'(?m)^\s*\r?\n','' -creplace '$?',"" -creplace "$","<br>`r`n"

        # Variables Output
        # $AdamjRemoveWSUSDriversSQLOutputTXT
        # $AdamjRemoveWSUSDriversSQLOutputHTML

    }
    function RemoveWSUSDriversPS {
        $Count = 0
        $AdamjWSUSServerAdminProxy.GetUpdates() | Where-Object { $_.IsDeclined -eq $true -and $_.UpdateClassificationTitle -eq "Drivers" } | ForEach-Object {
            # Delete these updates
            $AdamjWSUSServerAdminProxy.DeleteUpdate($_.Id.UpdateId.ToString())
            $DeleteDeclinedDriverTitle = $_.Title
            $Count++
            $AdamjRemoveWSUSDriversPSDeleteOutputTXT += "$($Count). $($DeleteDeclinedDriverTitle)`n`n"
            $AdamjRemoveWSUSDriversPSDeleteOutputHTML += "<li>$DeleteDeclinedDriverTitle</li>`n"
        }
        $AdamjRemoveWSUSDriversPSDeleteOutputTXT += "`n`n"
        $AdamjRemoveWSUSDriversPSDeleteOutputHTML += "</ol>`n"

        $Script:AdamjRemoveWSUSDriversPSOutputTXT += "`n`n"
        $Script:AdamjRemoveWSUSDriversPSOutputHTML += "<ol>`n"
        $Script:AdamjRemoveWSUSDriversPSOutputTXT += $AdamjRemoveWSUSDriversPSDeleteOutputTXT
        $Script:AdamjRemoveWSUSDriversPSOutputHTML += $AdamjRemoveWSUSDriversPSDeleteOutputHTML

        # Variables Output
        # $AdamjRemoveWSUSDriversPSOutputTXT
        # $AdamjRemoveWSUSDriversPSOutputHTML
    }
    # Process the appropriate internal function
    $DateNow = Get-Date
    if ($SQL -eq $True) { RemoveWSUSDriversSQL } else { RemoveWSUSDriversPS }
    $FinishedRunning = Get-Date
    $DifferenceInTime = New-TimeSpan –Start $DateNow –End $FinishedRunning
    # Create the output for the RemoveWSUSDrivers function
    $Script:AdamjRemoveWSUSDriversOutputTXT += "Adamj Remove WSUS Drivers:`n`n"
    $Script:AdamjRemoveWSUSDriversOutputHTML += "<p><span style=`"font-weight: bold; font-size: 1.2em;`">Adamj Remove WSUS Drivers:</span></p>`n"
    if ($SQL -eq $True) {
        $Script:AdamjRemoveWSUSDriversOutputTXT += $AdamjRemoveWSUSDriversSQLOutputTXT
        $Script:AdamjRemoveWSUSDriversOutputHTML += $AdamjRemoveWSUSDriversSQLOutputHTML
    } else {
        $Script:AdamjRemoveWSUSDriversOutputTXT += $AdamjRemoveWSUSDriversPSOutputTXT
        $Script:AdamjRemoveWSUSDriversOutputHTML += $AdamjRemoveWSUSDriversPSOutputHTML
    }
    $Script:AdamjRemoveWSUSDriversOutputTXT += "Remove WSUS Drivers Stream Duration: {0:00}:{1:00}:{2:00}:{3:00}`r`n`r`n" -f ($DifferenceInTime | % {$_.Days, $_.Hours, $_.Minutes, $_.Seconds})
    $Script:AdamjRemoveWSUSDriversOutputHTML += "<p>Remove WSUS Drivers Stream Duration: {0:00}:{1:00}:{2:00}:{3:00}</p>`r`n" -f ($DifferenceInTime | % {$_.Days, $_.Hours, $_.Minutes, $_.Seconds})

    # Variables Output
    # $AdamjRemoveWSUSDriversOutputTXT
    # $AdamjRemoveWSUSDriversOutputHTML
}
#endregion RemoveWSUSDrivers Function

#region RemoveDeclinedWSUSUpdates Function
################################
#  Adamj Remove Declined WSUS  #
#       Updates Stream         #
################################

function RemoveDeclinedWSUSUpdates {
    param (
    [Switch]$Display,
    [Switch]$Proceed
    )
    # Log the date first
    $DateNow = Get-Date
    Write-Verbose "Create an update scope"
    $UpdateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
    Write-Verbose "By default the update scope is created for any approval states"
    $UpdateScope.ApprovedStates = "Any"
    Write-Verbose "Get all updates that have been Superseded and not Declined"
    $AdamjRemoveDeclinedWSUSUpdatesUpdates = $AdamjWSUSServerAdminProxy.GetUpdates($UpdateScope) | Where { ($_.isDeclined) }
    function RemoveDeclinedWSUSUpdatesCountUpdates {
        Write-Verbose "First count how many updates will be removed that are already declined updates - just for fun. I like fun :)"
        $Script:AdamjRemoveDeclinedWSUSUpdatesCountUpdatesCount = "{0:N0}" -f $AdamjRemoveDeclinedWSUSUpdatesUpdates.Count
        $Script:AdamjRemoveDeclinedWSUSUpdatesCountUpdatesOutputTXT += "The number of declined updates that would be removed from the database are: $AdamjRemoveDeclinedWSUSUpdatesCountUpdatesCount.`r`n`r`n"
        $Script:AdamjRemoveDeclinedWSUSUpdatesCountUpdatesOutputHTML += "<p>The number of declined updates that would be removed from the database are: $AdamjRemoveDeclinedWSUSUpdatesCountUpdatesCount.</p>`n"

         # Variables Output
         # $AdamjRemoveDeclinedWSUSUpdatesCountUpdatesOutputTXT
         # $AdamjRemoveDeclinedWSUSUpdatesCountUpdatesOutputHTML
    }

    function RemoveDeclinedWSUSUpdatesDisplayUpdates {
        Write-Verbose "Display the titles of the declined updates that will be removed from the database - just for fun. I like fun :)"
        $Script:AdamjRemoveDeclinedWSUSUpdatesDisplayOutputHTML += "<ol>`n"
        $Count=0
        ForEach ($update in $AdamjRemoveDeclinedWSUSUpdatesUpdates) {
            $Count++
            $Script:AdamjRemoveDeclinedWSUSUpdatesDisplayOutputTXT += "$($Count). $($update.title) - https://support.microsoft.com/en-us/kb/$($update.KnowledgebaseArticles)`r`n"
            $Script:AdamjRemoveDeclinedWSUSUpdatesDisplayOutputHTML += "<li><a href=`"https://support.microsoft.com/en-us/kb/$($update.KnowledgebaseArticles)`">$($update.title)</a></li>`n"
        }
        $Script:AdamjRemoveDeclinedWSUSUpdatesDisplayOutputTXT += "`r`n"
        $Script:AdamjRemoveDeclinedWSUSUpdatesDisplayOutputHTML += "</ol>`n"

        # Variables Output
        # $AdamjRemoveDeclinedWSUSUpdatesDisplayOutputTXT
        # $AdamjRemoveDeclinedWSUSUpdatesDisplayOutputHTML
    }

    function RemoveDeclinedWSUSUpdatesProceed {
        Write-Output "You've chosen to remove declined updates from the database. Removing $AdamjRemoveDeclinedWSUSUpdatesCountUpdatesCount declined updates."
        Write-Output ""
        Write-Output "Please be patient, this may take a while."
        Write-Output ""
        Write-Output "It is not abnormal for this process to take minutes, hours, or days. It varies per install and per execution."
        Write-Output ""
        Write-Output "Any errors received are due to updates that are shared between systems. Eg. A Windows 7 update may share itself also with a Server 2008 update."
        Write-Output ""
        Write-Output "If you cancel this process (CTRL-C/Close the window), you will lose the documentation/log of what has happened thusfar, but it will resume where it left off when you run it again."
        $Script:AdamjRemoveDeclinedWSUSUpdatesProceedOutputTXT += "You've chosen to remove declined updates from the database. Removing $AdamjRemoveDeclinedWSUSUpdatesCountUpdatesCount declined updates.`r`n`r`n"
        $Script:AdamjRemoveDeclinedWSUSUpdatesProceedOutputHTML += "<p>You've chosen to remove declined updates from the database. <strong>Removing $AdamjRemoveDeclinedWSUSUpdatesCountUpdatesCount declined updates.</strong></p>`n"
        # Remove these updates
        $AdamjRemoveDeclinedWSUSUpdatesUpdates | ForEach-Object {
            $DeleteID = $_.Id.UpdateId.ToString()
            Try {
                $AdamjRemoveDeclinedWSUSUpdatesUpdateTitle = $($_.Title)
                Write-Output "Deleting" $AdamjRemoveDeclinedWSUSUpdatesUpdateTitle
                $AdamjWSUSServerAdminProxy.DeleteUpdate($DeleteId)
            }
            Catch {
                $ExceptionError = $_.Exception
                if ([string]::isnullorempty($AdamjRemoveDeclinedWSUSUpdatesProceedExceptionsTXT)) { $AdamjRemoveDeclinedWSUSUpdatesProceedExceptionsTXT = "" }
                if ([string]::isnullorempty($AdamjRemoveDeclinedWSUSUpdatesProceedExceptionsHTML)) { $AdamjRemoveDeclinedWSUSUpdatesProceedExceptionsHTML = "" }
                $AdamjRemoveDeclinedWSUSUpdatesProceedExceptionsTXT += "Error: $AdamjRemoveDeclinedWSUSUpdatesUpdateTitle`r`n`r`n$ExceptionError.InnerException`r`n`r`n"
                $AdamjRemoveDeclinedWSUSUpdatesProceedExceptionsHTML += "<li><p>$AdamjRemoveDeclinedWSUSUpdatesUpdateTitle</p>$ExceptionError.InnerException</li>"
            }
            Finally {
                if ($ExceptionError) {
                    Write-Output "Errors:" $ExceptionError.Message
                    Remove-Variable ExceptionError
                } else {
                    Write-Verbose "Successful"
                }
            }
        }
        if (-not [string]::isnullorempty($AdamjRemoveDeclinedWSUSUpdatesProceedExceptionsTXT)) {
            $Script:AdamjRemoveDeclinedWSUSUpdatesProceedOutputTXT += "*** Errors Removing Declined WSUS Updates ***`r`n"
            $Script:AdamjRemoveDeclinedWSUSUpdatesProceedOutputTXT += $AdamjRemoveDeclinedWSUSUpdatesProceedExceptionsTXT
            $Script:AdamjRemoveDeclinedWSUSUpdatesProceedOutputTXT += "`r`n`r`n"
        }
        if (-not [string]::isnullorempty($AdamjRemoveDeclinedWSUSUpdatesProceedExceptionsHTML)) {
            $Script:AdamjRemoveDeclinedWSUSUpdatesProceedOutputHTML += "<div class='error'><h1>Errors Removing Declined WSUS Updates</h1><ol start='1'>"
            $Script:AdamjRemoveDeclinedWSUSUpdatesProceedOutputHTML += $AdamjRemoveDeclinedWSUSUpdatesProceedExceptionsHTML
            $Script:AdamjRemoveDeclinedWSUSUpdatesProceedOutputHTML += "</ol></div>"
        }

        # Variables Output
        # $AdamjRemoveDeclinedWSUSUpdatesProceedOutputTXT
        # $AdamjRemoveDeclinedWSUSUpdatesProceedOutputHTML
    }

    RemoveDeclinedWSUSUpdatesCountUpdates
    if ($Display -ne $False) { RemoveDeclinedWSUSUpdatesDisplayUpdates }
    if ($Proceed -ne $False) { RemoveDeclinedWSUSUpdatesProceed }
    $FinishedRunning = Get-Date
    $DifferenceInTime = New-TimeSpan –Start $DateNow –End $FinishedRunning

    $Script:AdamjRemoveDeclinedWSUSUpdatesOutputTXT += "Adamj Remove Declined WSUS Updates:`r`n`r`n"
    $Script:AdamjRemoveDeclinedWSUSUpdatesOutputHTML += "<p><span style=`"font-weight: bold; font-size: 1.2em;`">Adamj Remove Declined WSUS Updates:</span></p>`n<ol>`n"
    $Script:AdamjRemoveDeclinedWSUSUpdatesOutputTXT += $AdamjRemoveDeclinedWSUSUpdatesCountUpdatesOutputTXT
    $Script:AdamjRemoveDeclinedWSUSUpdatesOutputHTML += $AdamjRemoveDeclinedWSUSUpdatesCountUpdatesOutputHTML
    if ($Display -ne $False) {
        $Script:AdamjRemoveDeclinedWSUSUpdatesOutputTXT += $AdamjRemoveDeclinedWSUSUpdatesDisplayOutputTXT
        $Script:AdamjRemoveDeclinedWSUSUpdatesOutputHTML += $AdamjRemoveDeclinedWSUSUpdatesDisplayOutputHTML
    }
    if ($Proceed -ne $False) {
        $Script:AdamjRemoveDeclinedWSUSUpdatesOutputTXT += $AdamjRemoveDeclinedWSUSUpdatesProceedOutputTXT
        $Script:AdamjRemoveDeclinedWSUSUpdatesOutputHTML += $AdamjRemoveDeclinedWSUSUpdatesProceedOutputHTML
    }
    $Script:AdamjRemoveDeclinedWSUSUpdatesOutputTXT += "Remove Declined WSUS Updates Stream Duration: {0:00}:{1:00}:{2:00}:{3:00}`r`n`r`n" -f ($DifferenceInTime | % {$_.Days, $_.Hours, $_.Minutes, $_.Seconds})
    $Script:AdamjRemoveDeclinedWSUSUpdatesOutputHTML += "<p>Remove Declined WSUS Updates Stream Duration: {0:00}:{1:00}:{2:00}:{3:00}</p>`r`n" -f ($DifferenceInTime | % {$_.Days, $_.Hours, $_.Minutes, $_.Seconds})
    
    # Variables Output
    # $AdamjRemoveDeclinedWSUSUpdatesOutputTXT
    # $AdamjRemoveDeclinedWSUSUpdatesOutputHTML
}
#endregion RemoveDeclinedWSUSUpdates Function

#region CompressUpdateRevisions Function
################################
#    Adamj Compress Update     #
#       Revisions Stream       #
################################

function CompressUpdateRevisions {
    Param (
    )
  $DateNow = Get-Date
  $AdamjCompressUpdateRevisionsSQLScript = @"
USE SUSDB;
GO
-- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.
SET NOCOUNT ON

DECLARE @var1 INT, @curitem INT, @totaltocompress INT
DECLARE @msg nvarchar(200)

IF EXISTS (
    SELECT * FROM tempdb.dbo.sysobjects o
    WHERE o.xtype IN ('U')
	AND o.id = object_id(N'tempdb..#results')
)
DROP TABLE #results
CREATE TABLE #results (Col1 INT)

-- Compress Update Revisions
INSERT INTO #results(Col1) EXEC spGetUpdatesToCompress
SET @totaltocompress = (SELECT COUNT(*) FROM #results)
SELECT @curitem=1
DECLARE WC Cursor FOR SELECT Col1 FROM #results;
OPEN WC
FETCH NEXT FROM WC INTO @var1 WHILE (@@FETCH_STATUS > -1)
BEGIN
	SET @msg = cast(@curitem as varchar(5)) + '/' + cast(@totaltocompress as varchar(5)) + ': Compressing ' + CONVERT(varchar(10), @var1) + ' ' + cast(getdate() as varchar(30))
	RAISERROR(@msg,0,1) WITH NOWAIT
	EXEC spCompressUpdate @localUpdateID=@var1
	SET @curitem = @curitem +1
	FETCH NEXT FROM WC INTO @var1
END
CLOSE WC
DEALLOCATE WC
DROP TABLE #results
"@
    Write-Verbose "Create a file with the content of the CompressUpdateRevisions Script above in the same working directory as this PowerShell script is running."
    $AdamjCompressUpdateRevisionsSQLScriptFile = "$AdamjScriptPath\AdamjCompressUpdateRevisions.sql"
    $AdamjCompressUpdateRevisionsSQLScript | Out-File "$AdamjCompressUpdateRevisionsSQLScriptFile"

    # Re-jig the $AdamjSQLConnectCommand to replace the $ with a `$ for Windows 2008 Internal Database possiblity.
    $AdamjSQLConnectCommand = $AdamjSQLConnectCommand.Replace('$','`$')
    Write-Verbose "Execute the SQL Script and store the results in a variable."
    $AdamjCompressUpdateRevisionsSQLScriptJobCommand = [scriptblock]::create("$AdamjSQLConnectCommand -i `"$AdamjCompressUpdateRevisionsSQLScriptFile`" -I")
    Write-Verbose "`$AdamjCompressUpdateRevisionsSQLScriptJob = $AdamjCompressUpdateRevisionsSQLScriptJobCommand"
    $AdamjCompressUpdateRevisionsSQLScriptJob = Start-Job -ScriptBlock $AdamjCompressUpdateRevisionsSQLScriptJobCommand
    Wait-Job $AdamjCompressUpdateRevisionsSQLScriptJob
    $AdamjCompressUpdateRevisionsSQLScriptJobOutput = Receive-Job $AdamjCompressUpdateRevisionsSQLScriptJob
    Remove-Job $AdamjCompressUpdateRevisionsSQLScriptJob
    Write-Verbose "Remove the SQL Script file."
    Remove-Item "$AdamjCompressUpdateRevisionsSQLScriptFile"
    $FinishedRunning = Get-Date
    $DifferenceInTime = New-TimeSpan –Start $DateNow –End $FinishedRunning
    # Setup variables to store the output to be added at the very end of the script for logging purposes.
    $Script:AdamjCompressUpdateRevisionsOutputTXT += "Adamj Compress Update Revisions:`r`n`r`n"
    $Script:AdamjCompressUpdateRevisionsOutputTXT += $AdamjCompressUpdateRevisionsSQLScriptJobOutput.Trim() -creplace'(?m)^\s*\r?\n','' -creplace '$?',"" -creplace "$","`r`n"
    $Script:AdamjCompressUpdateRevisionsOutputHTML += "<p><span style=`"font-weight: bold; font-size: 1.2em;`">Adamj Compress Update Revisions:</span></p>`n`n"
    $Script:AdamjCompressUpdateRevisionsOutputHTML += $AdamjCompressUpdateRevisionsSQLScriptJobOutput.Trim() -creplace'(?m)^\s*\r?\n','' -creplace '$?',"" -creplace "$","<br>`r`n"
    $Script:AdamjCompressUpdateRevisionsOutputTXT += "Adamj Compress Update Revisions Stream Duration: {0:00}:{1:00}:{2:00}:{3:00}`r`n`r`n" -f ($DifferenceInTime | % {$_.Days, $_.Hours, $_.Minutes, $_.Seconds})
    $Script:AdamjCompressUpdateRevisionsOutputHTML += "<p>Adamj Compress Update Revisions Stream Duration: {0:00}:{1:00}:{2:00}:{3:00}</p>`r`n" -f ($DifferenceInTime | % {$_.Days, $_.Hours, $_.Minutes, $_.Seconds})

    # Variables Output
    # $AdamjCompressUpdateRevisionsOutputTXT
    # $AdamjCompressUpdateRevisionsOutputHTML
}
#endregion CompressUpdateRevisions Function

#region RemoveObsoleteUpdates Function
################################
#    Adamj Remove Obsolete     #
#        Updates Stream        #
################################

function RemoveObsoleteUpdates {
    Param (
    )
  $DateNow = Get-Date
  $AdamjRemoveObsoleteUpdatesSQLScript = @"
USE SUSDB;
GO 
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON

DECLARE @var1 INT, @curitem INT, @totaltoremove INT
DECLARE @msg nvarchar(200)

IF EXISTS (
    SELECT * FROM tempdb.dbo.sysobjects o
    WHERE o.xtype IN ('U')
	AND o.id = object_id(N'tempdb..#results')
)
DROP TABLE #results
CREATE TABLE #results (Col1 INT)

-- Remove Obsolete Updates
INSERT INTO #results(Col1) EXEC spGetObsoleteUpdatesToCleanup
SET @totaltoremove = (SELECT COUNT(*) FROM #results)
SELECT @curitem=1
DECLARE WC Cursor FOR SELECT Col1 FROM #results
OPEN WC
FETCH NEXT FROM WC INTO @var1 WHILE (@@FETCH_STATUS > -1)
BEGIN
	SET @msg = cast(@curitem as varchar(5)) + '/' + cast(@totaltoremove as varchar(5)) + ': Deleting ' + CONVERT(varchar(10), @var1) + ' ' + cast(getdate() as varchar(30))
	RAISERROR(@msg,0,1) WITH NOWAIT
	EXEC spDeleteUpdate @localUpdateID=@var1
	SET @curitem = @curitem +1
	FETCH NEXT FROM WC INTO @var1
END
CLOSE WC
DEALLOCATE WC
DROP TABLE #results
"@
    Write-Output ""
    Write-Output "Please be patient, this may take a while."
    Write-Output ""
    Write-Output "It is not abnormal for this process to take minutes, hours, or days. It varies per install and per execution."
    Write-Output ""
    Write-Output "If you cancel this process (CTRL-C/Close the window), you will lose the documentation/log of what has happened thusfar, but it will resume where it left off when you run it again."
    Write-Verbose "Create a file with the content of the RemoveObsoleteUpdates Script above in the same working directory as this PowerShell script is running."
    $AdamjRemoveObsoleteUpdatesSQLScriptFile = "$AdamjScriptPath\AdamjRemoveObsoleteUpdates.sql"
    $AdamjRemoveObsoleteUpdatesSQLScript | Out-File "$AdamjRemoveObsoleteUpdatesSQLScriptFile"
    Write-Debug "Just wrote to script file"
    # Re-jig the $AdamjSQLConnectCommand to replace the $ with a `$ for Windows 2008 Internal Database possiblity.
    $AdamjSQLConnectCommand = $AdamjSQLConnectCommand.Replace('$','`$')
    Write-Verbose "Execute the SQL Script and store the results in a variable."
    $AdamjRemoveObsoleteUpdatesSQLScriptJobCommand = [scriptblock]::create("$AdamjSQLConnectCommand -i `"$AdamjRemoveObsoleteUpdatesSQLScriptFile`" -I")
    Write-Verbose "`$AdamjRemoveObsoleteUpdatesSQLScriptJobCommand = $AdamjRemoveObsoleteUpdatesSQLScriptJobCommand"
    $AdamjRemoveObsoleteUpdatesSQLScriptJob = Start-Job -ScriptBlock $AdamjRemoveObsoleteUpdatesSQLScriptJobCommand
    Wait-Job $AdamjRemoveObsoleteUpdatesSQLScriptJob
    $AdamjRemoveObsoleteUpdatesSQLScriptJobOutput = Receive-Job $AdamjRemoveObsoleteUpdatesSQLScriptJob
    Write-Debug "Just finished - check AdamjRemoveObsoleteUpdatesSQLScriptJobOutput"
    Remove-Job $AdamjRemoveObsoleteUpdatesSQLScriptJob
    Write-Verbose "Remove the SQL Script file."
    Remove-Item "$AdamjRemoveObsoleteUpdatesSQLScriptFile"
    $FinishedRunning = Get-Date
    $DifferenceInTime = New-TimeSpan –Start $DateNow –End $FinishedRunning
    # Setup variables to store the output to be added at the very end of the script for logging purposes.
    $Script:AdamjRemoveObsoleteUpdatesOutputTXT += "Adamj Remove Obsolete Updates:`r`n`r`n"
    $Script:AdamjRemoveObsoleteUpdatesOutputTXT += $AdamjRemoveObsoleteUpdatesSQLScriptJobOutput.Trim() -creplace'(?m)^\s*\r?\n','' -creplace '$?',"" -creplace "$","`r`n"
    $Script:AdamjRemoveObsoleteUpdatesOutputHTML += "<p><span style=`"font-weight: bold; font-size: 1.2em;`">Adamj Remove Obsolete Updates:</span></p>`n`n"
    $Script:AdamjRemoveObsoleteUpdatesOutputHTML += $AdamjRemoveObsoleteUpdatesSQLScriptJobOutput.Trim() -creplace'(?m)^\s*\r?\n','' -creplace '$?',"" -creplace "$","<br>`r`n"
    $Script:AdamjRemoveObsoleteUpdatesOutputTXT += "Adamj Remove Obsolete Updates Stream Duration: {0:00}:{1:00}:{2:00}:{3:00}`r`n`r`n" -f ($DifferenceInTime | % {$_.Days, $_.Hours, $_.Minutes, $_.Seconds})
    $Script:AdamjRemoveObsoleteUpdatesOutputHTML += "<p>Adamj Remove Obsolete Updates Stream Duration: {0:00}:{1:00}:{2:00}:{3:00}</p>`r`n" -f ($DifferenceInTime | % {$_.Days, $_.Hours, $_.Minutes, $_.Seconds})

    # Variables Output
    # $AdamjRemoveObsoleteUpdatesOutputTXT
    # $AdamjRemoveObsoleteUpdatesOutputHTML
}
#endregion RemoveObsoleteUpdates Function

#region WSUSDBMaintenance Function
################################
#  Adamj WSUS DB Maintenance   #
#            Stream            #
################################

function WSUSDBMaintenance {
    Param (
    [Switch]$NoOutput
    )
  $DateNow = Get-Date
  $AdamjWSUSDBMaintenanceSQLScript = @"
/*
################################
#   Adamj WSUSDBMaintenance    #
#         SQL Script           #
#       Version 1.0            #
#      Taken from TechNet      #
#      referenced below.       #
#                              #
#        Adam Marshall         #
#     http://www.adamj.org     #
################################
*/
-- Taken from https://gallery.technet.microsoft.com/scriptcenter/6f8cde49-5c52-4abd-9820-f1d270ddea61

/******************************************************************************
This sample T-SQL script performs basic maintenance tasks on SUSDB
1. Identifies indexes that are fragmented and defragments them. For certain
   tables, a fill-factor is set in order to improve insert performance.
   Based on MSDN sample at http://msdn2.microsoft.com/en-us/library/ms188917.aspx
   and tailored for SUSDB requirements
2. Updates potentially out-of-date table statistics.
******************************************************************************/

USE SUSDB;
GO
SET NOCOUNT ON;

-- Rebuild or reorganize indexes based on their fragmentation levels
DECLARE @work_to_do TABLE (
    objectid int
    , indexid int
    , pagedensity float
    , fragmentation float
    , numrows int
)

DECLARE @objectid int;
DECLARE @indexid int;
DECLARE @schemaname nvarchar(130);
DECLARE @objectname nvarchar(130);
DECLARE @indexname nvarchar(130);
DECLARE @numrows int
DECLARE @density float;
DECLARE @fragmentation float;
DECLARE @command nvarchar(4000);
DECLARE @fillfactorset bit
DECLARE @numpages int

-- Select indexes that need to be defragmented based on the following
-- * Page density is low
-- * External fragmentation is high in relation to index size
PRINT 'Estimating fragmentation: Begin. ' + convert(nvarchar, getdate(), 121)
INSERT @work_to_do
SELECT
    f.object_id
    , index_id
    , avg_page_space_used_in_percent
    , avg_fragmentation_in_percent
    , record_count
FROM
    sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL , NULL, 'SAMPLED') AS f
WHERE
    (f.avg_page_space_used_in_percent < 85.0 and f.avg_page_space_used_in_percent/100.0 * page_count < page_count - 1)
    or (f.page_count > 50 and f.avg_fragmentation_in_percent > 15.0)
    or (f.page_count > 10 and f.avg_fragmentation_in_percent > 80.0)

PRINT 'Number of indexes to rebuild: ' + cast(@@ROWCOUNT as nvarchar(20))

PRINT 'Estimating fragmentation: End. ' + convert(nvarchar, getdate(), 121)

SELECT @numpages = sum(ps.used_page_count)
FROM
    @work_to_do AS fi
    INNER JOIN sys.indexes AS i ON fi.objectid = i.object_id and fi.indexid = i.index_id
    INNER JOIN sys.dm_db_partition_stats AS ps on i.object_id = ps.object_id and i.index_id = ps.index_id

-- Declare the cursor for the list of indexes to be processed.
DECLARE curIndexes CURSOR FOR SELECT * FROM @work_to_do

-- Open the cursor.
OPEN curIndexes

-- Loop through the indexes
WHILE (1=1)
BEGIN
    FETCH NEXT FROM curIndexes
    INTO @objectid, @indexid, @density, @fragmentation, @numrows;
    IF @@FETCH_STATUS < 0 BREAK;

    SELECT
        @objectname = QUOTENAME(o.name)
        , @schemaname = QUOTENAME(s.name)
    FROM
        sys.objects AS o
        INNER JOIN sys.schemas as s ON s.schema_id = o.schema_id
    WHERE
        o.object_id = @objectid;

    SELECT
        @indexname = QUOTENAME(name)
        , @fillfactorset = CASE fill_factor WHEN 0 THEN 0 ELSE 1 END
    FROM
        sys.indexes
    WHERE
        object_id = @objectid AND index_id = @indexid;

    IF ((@density BETWEEN 75.0 AND 85.0) AND @fillfactorset = 1) OR (@fragmentation < 30.0)
        SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REORGANIZE';
    ELSE IF @numrows >= 5000 AND @fillfactorset = 0
        SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REBUILD WITH (FILLFACTOR = 90)';
    ELSE
        SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REBUILD';
    PRINT convert(nvarchar, getdate(), 121) + N' Executing: ' + @command;
    EXEC (@command);
    PRINT convert(nvarchar, getdate(), 121) + N' Done.';
END

-- Close and deallocate the cursor.
CLOSE curIndexes;
DEALLOCATE curIndexes;

IF EXISTS (SELECT * FROM @work_to_do)
BEGIN
    PRINT 'Estimated number of pages in fragmented indexes: ' + cast(@numpages as nvarchar(20))
    SELECT @numpages = @numpages - sum(ps.used_page_count)
    FROM
        @work_to_do AS fi
        INNER JOIN sys.indexes AS i ON fi.objectid = i.object_id and fi.indexid = i.index_id
        INNER JOIN sys.dm_db_partition_stats AS ps on i.object_id = ps.object_id and i.index_id = ps.index_id
    PRINT 'Estimated number of pages freed: ' + cast(@numpages as nvarchar(20))
END
GO

--Update all statistics
PRINT 'Updating all statistics.' + convert(nvarchar, getdate(), 121)
EXEC sp_updatestats
PRINT 'Done updating statistics.' + convert(nvarchar, getdate(), 121)
GO
"@
    Write-Verbose "Create a file with the content of the WSUSDBMaintenance Script above in the same working directory as this PowerShell script is running."
    $AdamjWSUSDBMaintenanceSQLScriptFile = "$AdamjScriptPath\AdamjWSUSDBMaintenance.sql"
    $AdamjWSUSDBMaintenanceSQLScript | Out-File "$AdamjWSUSDBMaintenanceSQLScriptFile"

    # Re-jig the $AdamjSQLConnectCommand to replace the $ with a `$ for Windows 2008 Internal Database possiblity.
    $AdamjSQLConnectCommand = $AdamjSQLConnectCommand.Replace('$','`$')
    Write-Verbose "Execute the SQL Script and store the results in a variable."
    $AdamjWSUSDBMaintenanceSQLScriptJobCommand = [scriptblock]::create("$AdamjSQLConnectCommand -i `"$AdamjWSUSDBMaintenanceSQLScriptFile`" -I")
    Write-Verbose "`$AdamjWSUSDBMaintenanceSQLScriptJobCommand = $AdamjWSUSDBMaintenanceSQLScriptJobCommand"
    $AdamjWSUSDBMaintenanceSQLScriptJob = Start-Job -ScriptBlock $AdamjWSUSDBMaintenanceSQLScriptJobCommand
    Wait-Job $AdamjWSUSDBMaintenanceSQLScriptJob
    $AdamjWSUSDBMaintenanceSQLScriptJobOutput = Receive-Job $AdamjWSUSDBMaintenanceSQLScriptJob
    Remove-Job $AdamjWSUSDBMaintenanceSQLScriptJob
    Write-Verbose "Remove the SQL Script file."
    Remove-Item "$AdamjWSUSDBMaintenanceSQLScriptFile"
    $FinishedRunning = Get-Date
    $DifferenceInTime = New-TimeSpan –Start $DateNow –End $FinishedRunning
    # Setup variables to store the output to be added at the very end of the script for logging purposes.
    if ($NoOutput -eq $False) {
        $Script:AdamjWSUSDBMaintenanceOutputTXT += "Adamj WSUS DB Maintenance:`r`n`r`n"
        $Script:AdamjWSUSDBMaintenanceOutputTXT += $AdamjWSUSDBMaintenanceSQLScriptJobOutput.Trim() -creplace'(?m)^\s*\r?\n','' -creplace '$?',"" -creplace "$","`r`n"
        $Script:AdamjWSUSDBMaintenanceOutputHTML += "<p><span style=`"font-weight: bold; font-size: 1.2em;`">Adamj WSUS DB Maintenance:</span></p>`n`n"
        $Script:AdamjWSUSDBMaintenanceOutputHTML += $AdamjWSUSDBMaintenanceSQLScriptJobOutput.Trim() -creplace'(?m)^\s*\r?\n','' -creplace '$?',"" -creplace "$","<br>`r`n"
     } else {
        $Script:AdamjWSUSDBMaintenanceOutputTXT += "Adamj WSUS DB Maintenance:`r`n`r`n"
        $Script:AdamjWSUSDBMaintenanceOutputTXT += "The Adamj WSUS DB Maintenance Stream was run with the -NoOutput switch.`r`n"
        $Script:AdamjWSUSDBMaintenanceOutputHTML += "<p><span style=`"font-weight: bold; font-size: 1.2em;`">Adamj WSUS DB Maintenance:</span></p>`n`n"
        $Script:AdamjWSUSDBMaintenanceOutputHTML += "<p>The Adamj WSUS DB Maintenance Stream was run with the -NoOutput switch.</p>`n`n"
     }
     $Script:AdamjWSUSDBMaintenanceOutputTXT += "WSUS DB Maintenance Stream Duration: {0:00}:{1:00}:{2:00}:{3:00}`r`n`r`n" -f ($DifferenceInTime | % {$_.Days, $_.Hours, $_.Minutes, $_.Seconds})
     $Script:AdamjWSUSDBMaintenanceOutputHTML += "<p>WSUS DB Maintenance Stream Duration: {0:00}:{1:00}:{2:00}:{3:00}</p>`r`n" -f ($DifferenceInTime | % {$_.Days, $_.Hours, $_.Minutes, $_.Seconds})

    # Variables Output
    # $AdamjWSUSDBMaintenanceOutputTXT
    # $AdamjWSUSDBMaintenanceOutputHTML
}
#endregion WSUSDBMaintenance Function

#region DeclineSupersededUpdates Function
################################
#   Adamj Decline Superseded   #
#        Updates Stream        #
################################

function DeclineSupersededUpdates {
    param (
    [Switch]$Display,
    [Switch]$Proceed
    )
    # Log the date first
    $DateNow = Get-Date
    Write-Verbose "Create an update scope"
    $UpdateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
    Write-Verbose "By default the update scope is created for any approval states"
    $UpdateScope.ApprovedStates = "Any"
    Write-Verbose "Get all updates that have been superseded and not declined"
    $AdamjDeclineSupersededUpdatesUpdates = $AdamjWSUSServerAdminProxy.GetUpdates($UpdateScope) | Where { ($_.IsSuperseded) -and -not ($_.isDeclined) }
    function DeclineSupersededUpdatesCountUpdates {
        Write-Verbose "First count how many updates will be declined by declining superseded Updates - just for fun. I like fun :)"
        $Script:AdamjDeclineSupersededUpdatesCountUpdatesCount = "{0:N0}" -f $AdamjDeclineSupersededUpdatesUpdates.Count
        $Script:AdamjDeclineSupersededUpdatesCountUpdatesOutputTXT += "The number of superseded updates that would be declined is: $AdamjDeclineSupersededUpdatesCountUpdatesCount.`r`n"
        $Script:AdamjDeclineSupersededUpdatesCountUpdatesOutputHTML += "<p>The number of superseded updates that would be declined is: $AdamjDeclineSupersededUpdatesCountUpdatesCount.</p>`n"

         # Variables Output
         # $AdamjDeclineSupersededUpdatesCountUpdatesOutputTXT
         # $AdamjDeclineSupersededUpdatesCountUpdatesOutputTXT
    }
    function DeclineSupersededUpdatesDisplayUpdates {
        Write-Verbose "Display the titles of the Superseded updates that will be declined - just for fun. I like fun :)"
        $Script:AdamjDeclineSupersededUpdatesUpdatesDisplayOutputHTML += "<ol>`n"
        $Count=0
        ForEach ($update in $AdamjDeclineSupersededUpdatesUpdates) {
            $Count++
            $Script:AdamjDeclineSupersededUpdatesUpdatesDisplayOutputTXT += "$($Count). $($update.title) - https://support.microsoft.com/en-us/kb/$($update.KnowledgebaseArticles)`r`n"
            $Script:AdamjDeclineSupersededUpdatesUpdatesDisplayOutputHTML += "<li><a href=`"https://support.microsoft.com/en-us/kb/$($update.KnowledgebaseArticles)`">$($update.title)</a></li>`n"
        }
        $Script:AdamjDeclineSupersededUpdatesUpdatesDisplayOutputTXT += "`r`n"
        $Script:AdamjDeclineSupersededUpdatesUpdatesDisplayOutputHTML += "</ol>`n"

        # Variables Output
        # $AdamjDeclineSupersededUpdatesUpdatesDisplayOutputTXT
        # $AdamjDeclineSupersededUpdatesUpdatesDisplayOutputHTML
    }
    function DeclineSupersededUpdatesProceed {
        $Script:AdamjDeclineSupersededUpdatesProceedOutputTXT += "You've chosen to Decline Superseded Updates. Declining $AdamjDeclineSupersededUpdatesCountUpdatesCount Superseded updates.`r`n`r`n"
        $Script:AdamjDeclineSupersededUpdatesProceedOutputHTML += "<p>You've chosen to Decline Superseded Updates. <strong>Declining $AdamjDeclineSupersededUpdatesCountUpdatesCount Superseded updates.</strong></p>`n"
        Write-Verbose "Decline these updates"
        $AdamjDeclineSupersededUpdatesUpdates | ForEach-Object -Process { $_.Decline() }

        # Variables Output
        # $AdamjDeclineSupersededUpdatesProceedOutputTXT
        # $AdamjDeclineSupersededUpdatesProceedOutputHTML
    }

    DeclineSupersededUpdatesCountUpdates
    if ($Display -ne $False) { DeclineSupersededUpdatesDisplayUpdates }
    if ($Proceed -ne $False) { DeclineSupersededUpdatesProceed }
    $FinishedRunning = Get-Date
    $DifferenceInTime = New-TimeSpan –Start $DateNow –End $FinishedRunning

    $Script:AdamjDeclineSupersededUpdatesOutputTXT += "Adamj Decline Superseded Updates:`r`n"
    $Script:AdamjDeclineSupersededUpdatesOutputHTML += "<p><span style=`"font-weight: bold; font-size: 1.2em;`">Adamj Decline Superseded Updates:</span><br>`n"
    $Script:AdamjDeclineSupersededUpdatesOutputTXT += $AdamjDeclineSupersededUpdatesCountUpdatesOutputTXT
    $Script:AdamjDeclineSupersededUpdatesOutputHTML += $AdamjDeclineSupersededUpdatesCountUpdatesOutputHTML
    if ($Display -ne $False) {
        $Script:AdamjDeclineSupersededUpdatesOutputTXT += $AdamjDeclineSupersededUpdatesUpdatesDisplayOutputTXT
        $Script:AdamjDeclineSupersededUpdatesOutputHTML += $AdamjDeclineSupersededUpdatesUpdatesDisplayOutputHTML
    }
    if ($Proceed -ne $False) {
        $Script:AdamjDeclineSupersededUpdatesOutputTXT += $AdamjDeclineSupersededUpdatesProceedOutputTXT
        $Script:AdamjDeclineSupersededUpdatesOutputHTML += $AdamjDeclineSupersededUpdatesProceedOutputHTML
    }
    $Script:AdamjDeclineSupersededUpdatesOutputTXT += "Decline Superseded Updates Stream Duration: {0:00}:{1:00}:{2:00}:{3:00}`r`n`r`n" -f ($DifferenceInTime | % {$_.Days, $_.Hours, $_.Minutes, $_.Seconds})
    $Script:AdamjDeclineSupersededUpdatesOutputHTML += "<p>Decline Superseded Updates Stream Duration: {0:00}:{1:00}:{2:00}:{3:00}</p>`r`n" -f ($DifferenceInTime | % {$_.Days, $_.Hours, $_.Minutes, $_.Seconds})
}
#endregion DeclineSupersededUpdates Function

#region CleanUpWSUSSynchronizationLogs Function
################################
#        Clean Up WSUS         #
# Synchronization Logs Stream  #
################################

function CleanUpWSUSSynchronizationLogs {
    Param(
    [Int]$ConsistencyNumber,
    [String]$ConsistencyTime,
    [Switch]$All
    )
  $DateNow = Get-Date
  $AdamjCleanUpWSUSSynchronizationLogsSQLScript = @"
/*
################################
#  Adamj WSUS Synchronization  #
#      Cleanup SQL Script      #
#       Version 1.0            #
#  Taken from various sources  #
#      from the Internet.      #
#                              #
#  Modified By: Adam Marshall  #
#     http://www.adamj.org     #
################################
*/
$(
    if ($ConsistencyNumber -ne "0") {
    $("
USE SUSDB
GO
DELETE FROM tbEventInstance WHERE EventNamespaceID = '2' AND EVENTID IN ('381', '382', '384', '386', '387', '389') AND DATEDIFF($($ConsistencyTime), TimeAtServer, CURRENT_TIMESTAMP) >= $($ConsistencyNumber);
GO")
}
elseif ($All -ne $False) {
$("USE SUSDB
GO
DELETE FROM tbEventInstance WHERE EventNamespaceID = '2' AND EVENTID IN ('381', '382', '384', '386', '387', '389')
GO")
}
)
"@
    Write-Verbose "Create a file with the content of the AdamjCleanUpWSUSSynchronizationLogs Script above in the same working directory as this PowerShell script is running."
    $AdamjCleanUpWSUSSynchronizationLogsSQLScriptFile = "$AdamjScriptPath\AdamjCleanUpWSUSSynchronizationLogs.sql"
    $AdamjCleanUpWSUSSynchronizationLogsSQLScript | Out-File "$AdamjCleanUpWSUSSynchronizationLogsSQLScriptFile"
    # Re-jig the $AdamjSQLConnectCommand to replace the $ with a `$ for Windows 2008 Internal Database possiblity.
    $AdamjSQLConnectCommand = $AdamjSQLConnectCommand.Replace('$','`$')
    Write-Verbose "Execute the SQL Script and store the results in a variable."
    $AdamjCleanUpWSUSSynchronizationLogsSQLScriptJobCommand = [scriptblock]::create("$AdamjSQLConnectCommand -i `"$AdamjCleanUpWSUSSynchronizationLogsSQLScriptFile`" -I")
    Write-Verbose "`$AdamjCleanUpWSUSSynchronizationLogsSQLScriptJobCommand = $AdamjCleanUpWSUSSynchronizationLogsSQLScriptJobCommand"
    $AdamjCleanUpWSUSSynchronizationLogsSQLScriptJob = Start-Job -ScriptBlock $AdamjCleanUpWSUSSynchronizationLogsSQLScriptJobCommand
    Wait-Job $AdamjCleanUpWSUSSynchronizationLogsSQLScriptJob
    $AdamjCleanUpWSUSSynchronizationLogsSQLScriptJobOutput = Receive-Job $AdamjCleanUpWSUSSynchronizationLogsSQLScriptJob
    Remove-Job $AdamjCleanUpWSUSSynchronizationLogsSQLScriptJob
    Write-Verbose "Remove the SQL Script file."
    Remove-Item "$AdamjCleanUpWSUSSynchronizationLogsSQLScriptFile"
    $FinishedRunning = Get-Date
    $DifferenceInTime = New-TimeSpan –Start $DateNow –End $FinishedRunning

    # Setup variables to store the output to be added at the very end of the script for logging purposes.
    $Script:AdamjCleanUpWSUSSynchronizationLogsSQLOutputTXT += "Adamj Clean Up WSUS Synchronization Logs:`r`n`r`n"
    $Script:AdamjCleanUpWSUSSynchronizationLogsSQLOutputTXT += $AdamjCleanUpWSUSSynchronizationLogsSQLScriptJobOutput.Trim() -creplace'(?m)^\s*\r?\n','' -creplace '$?',"" -creplace "$","`r`n"
    $Script:AdamjCleanUpWSUSSynchronizationLogsSQLOutputTXT += "Clean Up WSUS Synchronization Logs Stream Duration: {0:00}:{1:00}:{2:00}:{3:00}`r`n`r`n" -f ($DifferenceInTime | % {$_.Days, $_.Hours, $_.Minutes, $_.Seconds})

    $Script:AdamjCleanUpWSUSSynchronizationLogsSQLOutputHTML += "<p><span style=`"font-weight: bold; font-size: 1.2em;`">Adamj Clean Up WSUS Synchronization Logs:</span></p>`r`n"
    $Script:AdamjCleanUpWSUSSynchronizationLogsSQLOutputHTML += $AdamjCleanUpWSUSSynchronizationLogsSQLScriptJobOutput.Trim() -creplace'(?m)^\s*\r?\n','' -creplace '$?',"" -creplace "$","<br>`r`n"
    $Script:AdamjCleanUpWSUSSynchronizationLogsSQLOutputHTML += "<p>Clean Up WSUS Synchronization Logs Stream Duration: {0:00}:{1:00}:{2:00}:{3:00}</p>`r`n" -f ($DifferenceInTime | % {$_.Days, $_.Hours, $_.Minutes, $_.Seconds})

    # Variables Output
    # $AdamjCleanUpWSUSSynchronizationLogsSQLOutputTXT
    # $AdamjCleanUpWSUSSynchronizationLogsSQLOutputHTML
    
}
#endregion CleanUpWSUSSynchronizationLogs Function

#region ComputerObjectCleanup Function
################################
#   Computer Object Cleanup    #
#            Stream            #
################################

function ComputerObjectCleanup {
    $DateNow = Get-Date
    Write-Verbose "Create a new timespan using `$AdamjComputerObjectCleanupSearchDays and find how many computers need to be cleaned up"
    $AdamjComputerObjectCleanupSearchTimeSpan = New-Object timespan($AdamjComputerObjectCleanupSearchDays,0,0,0)
    $AdamjComputerObjectCleanupScope = New-Object Microsoft.UpdateServices.Administration.ComputerTargetScope
    $AdamjComputerObjectCleanupScope.ToLastSyncTime = [DateTime]::UtcNow.Subtract($AdamjComputerObjectCleanupSearchTimeSpan)
    $AdamjComputerObjectCleanupSet = $AdamjWSUSServerAdminProxy.GetComputerTargets($AdamjComputerObjectCleanupScope) | Sort-Object FullDomainName
    Write-Verbose "Clean up $($AdamjComputerObjectCleanupSet.Count) computer objects"
    $AdamjWSUSServerAdminProxy.GetComputerTargets($AdamjComputerObjectCleanupScope) | ForEach-Object { $_.Delete() }

    $FinishedRunning = Get-Date
    $DifferenceInTime = New-TimeSpan –Start $DateNow –End $FinishedRunning

    # Setup variables to store the output to be added at the very end of the script for logging purposes.
    $Script:AdamjComputerObjectCleanupOutputTXT += "Adamj Computer Object Cleanup:`r`n`r`n"
    if ($($AdamjComputerObjectCleanupSet.Count) -gt "0") {
        $Script:AdamjComputerObjectCleanupOutputTXT += "The following $($AdamjComputerObjectCleanupSet.Count) $(if ($($AdamjComputerObjectCleanupSet.Count) -eq "1") { "computer" } else { "computers" }) have been removed."
        $Script:AdamjComputerObjectCleanupOutputTXT += $AdamjComputerObjectCleanupSet | Select-Object FullDomainName,@{Expression="   "},LastSyncTime | Format-Table -AutoSize | Out-String
    } else { $Script:AdamjComputerObjectCleanupOutputTXT += "There are no computers to clean up.`r`n" }

    $Script:AdamjComputerObjectCleanupOutputTXT += "Adamj Computer Object Cleanup Stream Duration: {0:00}:{1:00}:{2:00}:{3:00}`r`n`r`n" -f ($DifferenceInTime | % {$_.Days, $_.Hours, $_.Minutes, $_.Seconds})
    $Script:AdamjComputerObjectCleanupOutputHTML += "<p><span style=`"font-weight: bold; font-size: 1.2em;`">Adamj Computer Object Cleanup:</span></p>`r`n"
    if ($($AdamjComputerObjectCleanupSet.Count) -gt "0") {
        $Script:AdamjComputerObjectCleanupOutputHTML += "<p>The following $($AdamjComputerObjectCleanupSet.Count) $(if ($($AdamjComputerObjectCleanupSet.Count) -eq "1") { "computer" } else { "computers" }) have been removed.</p>"
        $Script:AdamjComputerObjectCleanupOutputHTML += ($AdamjComputerObjectCleanupSet | Select-Object FullDomainName,LastSyncTime | ConvertTo-Html -Fragment) -replace "\<table\>",'<table class="gridtable">'
    } else { $Script:AdamjComputerObjectCleanupOutputHTML += "<p>There are no computers to clean up.</p>" }
    $Script:AdamjComputerObjectCleanupOutputHTML += "<p>Adamj Computer Object Cleanup Stream Duration: {0:00}:{1:00}:{2:00}:{3:00}</p>`r`n" -f ($DifferenceInTime | % {$_.Days, $_.Hours, $_.Minutes, $_.Seconds})

    # Variables Output
    # $AdamjComputerObjectCleanupOutputTXT
    # $AdamjComputerObjectCleanupOutputHTML
}

#endregion ComputerObjectCleanup Function

#region WSUSServerCleanupWizard Function
################################
#  WSUS Server Cleanup Wizard  #
#            Stream            #
################################

function WSUSServerCleanupWizard {
    $DateNow = Get-Date
    $WSUSServerCleanupWizardBody = "<p><span style=`"font-weight: bold; font-size: 1.2em;`">WSUS Server Cleanup Wizard:</span></p>" | Out-String
    $CleanupManager = $AdamjWSUSServerAdminProxy.GetCleanupManager();
    $CleanupScope = New-Object Microsoft.UpdateServices.Administration.CleanupScope ($AdamjSCWSupersededUpdatesDeclined,$AdamjSCWExpiredUpdatesDeclined,$AdamjSCWObsoleteUpdatesDeleted,$AdamjSCWUpdatesCompressed,$AdamjSCWObsoleteComputersDeleted,$AdamjSCWUnneededContentFiles);
    $AdamjCleanupResults = $CleanupManager.PerformCleanup($CleanupScope)
    $FinishedRunning = Get-Date
    $DifferenceInTime = New-TimeSpan –Start $DateNow –End $FinishedRunning

    $Script:AdamjWSUSServerCleanupWizardOutputTXT += "Adamj WSUS Server Cleanup Wizard:`r`n`r`n"
    $Script:AdamjWSUSServerCleanupWizardOutputTXT += "$AdamjWSUSServer`r`n"
    $Script:AdamjWSUSServerCleanupWizardOutputTXT += "Version: $($AdamjWSUSServerAdminProxy.Version)`r`n"
    #$Script:AdamjWSUSServerCleanupWizardOutputTXT += "Started: $($DateNow.ToString("yyyy.MM.dd hh:mm:ss tt zzz"))`r`n"
    $Script:AdamjWSUSServerCleanupWizardOutputTXT += "SupersededUpdatesDeclined: $($AdamjCleanupResults.SupersededUpdatesDeclined)`r`n"
    $Script:AdamjWSUSServerCleanupWizardOutputTXT += "ExpiredUpdatesDeclined: $($AdamjCleanupResults.ExpiredUpdatesDeclined)`r`n"
    $Script:AdamjWSUSServerCleanupWizardOutputTXT += "ObsoleteUpdatesDeleted: $($AdamjCleanupResults.ObsoleteUpdatesDeleted)`r`n"
    $Script:AdamjWSUSServerCleanupWizardOutputTXT += "UpdatesCompressed: $($AdamjCleanupResults.UpdatesCompressed)`r`n"
    $Script:AdamjWSUSServerCleanupWizardOutputTXT += "ObsoleteComputersDeleted: $($AdamjCleanupResults.ObsoleteComputersDeleted)`r`n"
    $Script:AdamjWSUSServerCleanupWizardOutputTXT += "DiskSpaceFreed (MB): $([math]::round($AdamjCleanupResults.DiskSpaceFreed/1MB, 2))`r`n"
    $Script:AdamjWSUSServerCleanupWizardOutputTXT += "DiskSpaceFreed (GB): $([math]::round($AdamjCleanupResults.DiskSpaceFreed/1GB, 2))`r`n"
    #$Script:AdamjWSUSServerCleanupWizardOutputTXT += "Finished: $($FinishedRunning.ToString("yyyy.MM.dd hh:mm:ss tt zzz"))`r`n"
    $Script:AdamjWSUSServerCleanupWizardOutputTXT += "WSUS Server Cleanup Wizard Duration: {0:00}:{1:00}:{2:00}:{3:00}`r`n`r`n" -f ($DifferenceInTime | % {$_.Days, $_.Hours, $_.Minutes, $_.Seconds})
    
    $Script:AdamjWSUSServerCleanupWizardOutputHTML += "<p><span style=`"font-weight: bold; font-size: 1.2em;`">Adamj WSUS Server Cleanup Wizard:</span></p>`r`n"
    #$Script:AdamjWSUSServerCleanupWizardOutputHTML += $AdamjCSSStyling + "`r`n"
    $Script:AdamjWSUSServerCleanupWizardOutputHTML += "<table class=`"gridtable`">`r`n"
    $Script:AdamjWSUSServerCleanupWizardOutputHTML += "<tbody>`r`n"
    $Script:AdamjWSUSServerCleanupWizardOutputHTML += "<tr><th colspan=`"2`" rowspan=`"1`">$AdamjWSUSServer</th></tr>`r`n"
    $Script:AdamjWSUSServerCleanupWizardOutputHTML += "<tr><td>Version:</td><td>$($AdamjWSUSServerAdminProxy.Version)</td></tr>`r`n"
    #$Script:AdamjWSUSServerCleanupWizardOutputHTML += "<tr><td>Started:</td><td>$($DateNow.ToString("yyyy.MM.dd hh:mm:ss tt zzz"))</td></tr>`r`n"
    $Script:AdamjWSUSServerCleanupWizardOutputHTML += "<tr><td>SupersededUpdatesDeclined:</td><td>$($AdamjCleanupResults.SupersededUpdatesDeclined)</td></tr>`r`n"
    $Script:AdamjWSUSServerCleanupWizardOutputHTML += "<tr><td>ExpiredUpdatesDeclined:</td><td>$($AdamjCleanupResults.ExpiredUpdatesDeclined)</td></tr>`r`n"
    $Script:AdamjWSUSServerCleanupWizardOutputHTML += "<tr><td>ObsoleteUpdatesDeleted:</td><td>$($AdamjCleanupResults.ObsoleteUpdatesDeleted)</td></tr>`r`n"
    $Script:AdamjWSUSServerCleanupWizardOutputHTML += "<tr><td>UpdatesCompressed:</td><td>$($AdamjCleanupResults.UpdatesCompressed)</td></tr>`r`n"
    $Script:AdamjWSUSServerCleanupWizardOutputHTML += "<tr><td>ObsoleteComputersDeleted:</td><td>$($AdamjCleanupResults.ObsoleteComputersDeleted)</td></tr>`r`n"
    $Script:AdamjWSUSServerCleanupWizardOutputHTML += "<tr><td>DiskSpaceFreed (MB):</td><td>$([math]::round($AdamjCleanupResults.DiskSpaceFreed/1MB, 2))</td></tr>`r`n"
    $Script:AdamjWSUSServerCleanupWizardOutputHTML += "<tr><td>DiskSpaceFreed (GB):</td><td>$([math]::round($AdamjCleanupResults.DiskSpaceFreed/1GB, 2))</td></tr>`r`n"
    #$Script:AdamjWSUSServerCleanupWizardOutputHTML += "<tr><td>Finished:</td><td>$($FinishedRunning.ToString("yyyy.MM.dd hh:mm:ss tt zzz"))</td></tr>`r`n"
    $Script:AdamjWSUSServerCleanupWizardOutputHTML += "<tr><td>WSUS Server Cleanup Wizard Duration:</td><td>{0:00}:{1:00}:{2:00}:{3:00}</td></tr>`r`n" -f ($DifferenceInTime | % {$_.Days, $_.Hours, $_.Minutes, $_.Seconds})
    $Script:AdamjWSUSServerCleanupWizardOutputHTML += "</tbody>`r`n"
    $Script:AdamjWSUSServerCleanupWizardOutputHTML += "</table>`r`n"

    # Variables Output
    # $AdamjWSUSServerCleanupWizardOutputTXT
    # $AdamjWSUSServerCleanupWizardOutputHTML
}
#endregion WSUSServerCleanupWizard Function

#region AdamjScriptDifferenceInTime Function
function AdamjScriptDifferenceInTime {
    $AdamjScriptFinishedRunning = Get-Date
    $Script:AdamjScriptDifferenceInTime = New-TimeSpan –Start $AdamjScriptTime –End $AdamjScriptFinishedRunning
}
#endregion AdamjScriptDifferenceInTime Function

#region Create The CSS Styling
################################
#    Create the CSS Styling    #
################################

$AdamjCSSStyling =@"
<style type="text/css">
table.gridtable {
    font-family: verdana,arial,sans-serif;
    font-size:11px;
    color:#333333;
    border-width: 1px;
    border-color: #666666;
    border-collapse: collapse;
}
table.gridtable th {
    border-width: 1px;
    padding: 8px;
    border-style: solid;
    border-color: #666666;
    background-color: #dedede;
}
table.gridtable td {
    border-width: 1px;
    padding: 8px;
    border-style: solid;
    border-color: #666666;
    background-color: #ffffff;
}
.TFtable{
    border-collapse:collapse;
}
.TFtable td{
    padding:7px;
    border:#4e95f4 1px solid;
}

/* provide some minimal visual accommodation for IE8 and below */
.TFtable tr{
    background: #b8d1f3;
}
/* Define the background color for all the ODD background rows */
.TFtable tr:nth-child(odd){
    background: #b8d1f3;
}
/* Define the background color for all the EVEN background rows */
.TFtable tr:nth-child(even){
    background: #dae5f4;
}
.error {
border: 2px solid;
margin: 10px 10px;
padding:15px 50px 15px 50px;
}
.error ol {
color: #D8000C;
}
.error ol li p {
color: #000;
background-color: transparent;
}
.error ol li {
background-color: #FFBABA;
margin: 10px 0;
}
</style>
"@
#endregion Create The CSS Styling

#region Create The Output
################################
#     Create the TXT output    #
################################

function CreateBodyTXT {
    $Script:AdamjBodyTXT = "`n"
    $Script:AdamjBodyTXT += $AdamjBodyHeaderTXT
    $Script:AdamjBodyTXT += $AdamjConnectedTXT
    $Script:AdamjBodyTXT += $AdamjRemoveObsoleteUpdatesOutputTXT
    $Script:AdamjBodyTXT += $AdamjCompressUpdateRevisionsOutputTXT
    $Script:AdamjBodyTXT += $AdamjDeclineSupersededUpdatesOutputTXT
    $Script:AdamjBodyTXT += $AdamjCleanUpWSUSSynchronizationLogsSQLOutputTXT
    $Script:AdamjBodyTXT += $AdamjRemoveWSUSDriversOutputTXT
    $Script:AdamjBodyTXT += $AdamjRemoveDeclinedWSUSUpdatesOutputTXT
    $Script:AdamjBodyTXT += $AdamjComputerObjectCleanupOutputTXT
    $Script:AdamjBodyTXT += $AdamjWSUSDBMaintenanceOutputTXT
    $Script:AdamjBodyTXT += $AdamjWSUSServerCleanupWizardOutputTXT
    $Script:AdamjBodyTXT += "Clean-WSUS Script Duration: {0:00}:{1:00}:{2:00}:{3:00}`r`n`r`n" -f ($AdamjScriptDifferenceInTime | % {$_.Days, $_.Hours, $_.Minutes, $_.Seconds})
    $Script:AdamjBodyTXT += $AdamjBodyFooterTXT
}

################################
#    Create the HTML output    #
################################

function CreateBodyHTML {
    $Script:AdamjBodyHTML = "`n"
    $Script:AdamjBodyHTML += $AdamjCSSStyling
    $Script:AdamjBodyHTML += $AdamjBodyHeaderHTML
    $Script:AdamjBodyHTML += $AdamjConnectedHTML
    $Script:AdamjBodyHTML += $AdamjRemoveObsoleteUpdatesOutputHTML
    $Script:AdamjBodyHTML += $AdamjCompressUpdateRevisionsOutputHTML
    $Script:AdamjBodyHTML += $AdamjDeclineSupersededUpdatesOutputHTML
    $Script:AdamjBodyHTML += $AdamjCleanUpWSUSSynchronizationLogsSQLOutputHTML
    $Script:AdamjBodyHTML += $AdamjRemoveWSUSDriversOutputHTML
    $Script:AdamjBodyHTML += $AdamjRemoveDeclinedWSUSUpdatesOutputHTML
    $Script:AdamjBodyHTML += $AdamjComputerObjectCleanupOutputHTML
    $Script:AdamjBodyHTML += $AdamjWSUSDBMaintenanceOutputHTML
    $Script:AdamjBodyHTML += $AdamjWSUSServerCleanupWizardOutputHTML
    $Script:AdamjBodyHTML += "<p>Clean-WSUS Script Duration: {0:00}:{1:00}:{2:00}:{3:00}</p>`r`n" -f ($AdamjScriptDifferenceInTime | % {$_.Days, $_.Hours, $_.Minutes, $_.Seconds})
    $Script:AdamjBodyHTML += $AdamjBodyFooterHTML
}
#endregion Create The Output

#region SaveReport
################################
#       Save the Report        #
################################

function SaveReport {
    Param(
    [ValidateSet("TXT","HTML")]
    [String]$ReportType = "TXT"
    )
    if ($ReportType -eq "HTML") {
        $AdamjBodyHTML | Out-File -FilePath "$AdamjScriptPath\$(get-date -f "yyyy.MM.dd-HH.mm.ss").htm"
    } else {
        $AdamjBodyTXT | Out-File -FilePath "$AdamjScriptPath\$(get-date -f "yyyy.MM.dd-HH.mm.ss").txt"
    }
}
#endregion SaveReport

#region MailReport
################################
#       Mail the Report        #
################################

function MailReport {
    param (
        [ValidateSet("TXT","HTML")]
        [String] $MessageContentType = "HTML"
    )
    $message = New-Object System.Net.Mail.MailMessage
    $mailer = New-Object System.Net.Mail.SmtpClient ($AdamjMailReportSMTPServer, $AdamjMailReportSMTPPort)
    $mailer.EnableSSL = $AdamjMailReportSMTPServerEnableSSL
    if ($AdamjMailReportSMTPServerUsername -ne "") {
        $mailer.Credentials = New-Object System.Net.NetworkCredential($AdamjMailReportSMTPServerUsername, $AdamjMailReportSMTPServerPassword)
    }
    $message.From = $AdamjMailReportEmailFromAddress
    $message.To.Add($AdamjMailReportEmailToAddress)
    $message.Subject = $AdamjMailReportEmailSubject
    $message.Body = if ($MessageContentType -eq "HTML") { $AdamjBodyHTML } else { $AdamjBodyTXT }
    $message.IsBodyHtml = if ($MessageContentType -eq "HTML") { $True } else { $False }
    $mailer.send(($message))
}
#endregion MailReport

#region HelpMe
################################
#           Help Me            #
################################

function HelpMe {
    ((Get-CimInstance Win32_OperatingSystem) | Format-List @{Name="OS Name";Expression={$_.Caption}}, @{Name="OS Architecture";Expression={$_.OSArchitecture}}, @{Name="Version";Expression={$_.Version}}, @{Name="ServicePackMajorVersion";Expression={$_.ServicePackMajorVersion}}, @{Name="ServicePackMinorVersion";Expression={$_.ServicePackMinorVersion}} | Out-String).Trim()
    Write-Output "PowerShell Version: $($PSVersionTable.PSVersion.ToString())"
    Write-Output "WSUS Version: $($AdamjWSUSServerAdminProxy.Version)"
    Write-Output "Replica Server: $($AdamjWSUSServerAdminProxy.GetConfiguration().IsReplicaServer)"
    Write-Output "The path to the WSUS Content folder is: $($AdamjWSUSServerAdminProxy.GetConfiguration().LocalContentCachePath)"
    Write-Output "Free Space on the WSUS Content folder Volume is: $((Get-DiskFree -Format | ? { $_.Type -like '*fixed*' } | Where-Object { ($_.Vol -eq ($AdamjWSUSServerAdminProxy.GetConfiguration().LocalContentCachePath).split("\")[0]) }).Avail)"
    Write-Output "All Volumes on the WSUS Server:"
    (Get-DiskFree -Format | Out-String).Trim()
    Write-Output ".NET Installed Versions"
    (Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse | Get-ItemProperty -Name Version -EA 0 | Where { $_.PSChildName -Match '^(?!S)\p{L}'} | Format-Table PSChildName, Version -AutoSize | Out-String).Trim()
    Write-Output "============================="
    Write-Output "All My Functions"
    Write-Output "============================="
    Show-MyFunctions
    Write-Output "============================="
    Write-Output "All My Variables"
    Write-Output "============================="
    Show-MyVariables
    Write-Output "============================="
    Write-Output " End of HelpMe Stream"
    Write-Output "============================="

}
#endregion HelpMe

#region Process The Functions
################################
#    Process the Functions     #
################################

if ($FirstRun -eq $True) {
    CreateAdamjHeader
    Write-Output "Executing RemoveWSUSDrivers"
    RemoveWSUSDrivers -SQL
    Write-Output "Executing RemoveObsoleteUpdates"
    if ($AdamjWSUSServerAdminProxy.GetConfiguration().IsReplicaServer -eq $False) { RemoveObsoleteUpdates } else { Write-Output "This WSUS Server is a Replica Server. You can't remove obsolete updates from a replica server. Skipping this stream."}
    Write-Output "Executing CompressUpdateRevisions"
    if ($AdamjWSUSServerAdminProxy.GetConfiguration().IsReplicaServer -eq $False) { CompressUpdateRevisions } else { Write-Output "This WSUS Server is a Replica Server. You can't compress update revisions from a replica server. Skipping this stream."}
    Write-Output "Executing DeclineSupersededUpdates"
    if ($AdamjWSUSServerAdminProxy.GetConfiguration().IsReplicaServer -eq $False) { DeclineSupersededUpdates -Display -Proceed } else { Write-Output "This WSUS Server is a Replica Server. You can't decline superseded updates from a replica server. Skipping this stream."}
    Write-Output "Executing CleanUpWSUSSynchronizationLogs"
    if ($AdamjCleanUpWSUSSynchronizationLogsAll -eq $True) { CleanUpWSUSSynchronizationLogs -All } else { CleanUpWSUSSynchronizationLogs -ConsistencyNumber $AdamjCleanUpWSUSSynchronizationLogsConsistencyNumber -ConsistencyTime $AdamjCleanUpWSUSSynchronizationLogsConsistencyTime }
    if ($AdamjComputerObjectCleanup -eq $True) { Write-Output "Executing ComputerObjectCleanup" ; ComputerObjectCleanup }
    Write-Output "Executing WSUSDBMaintenance"
    WSUSDBMaintenance
    Write-Output "Executing WSUSServerCleanupWizard"
    WSUSServerCleanupWizard
    CreateAdamjFooter
    AdamjScriptDifferenceInTime
    CreateBodyTXT
    CreateBodyHTML
    if ($AdamjMailReport -eq $True) { MailReport $AdamjMailReportType }
    SaveReport
}
if ($MonthlyRun -eq $True) {
    CreateAdamjHeader
    Write-Output "Executing RemoveObsoleteUpdates"
    if ($AdamjWSUSServerAdminProxy.GetConfiguration().IsReplicaServer -eq $False) { RemoveObsoleteUpdates } else { Write-Output "This WSUS Server is a Replica Server. You can't remove obsolete updates from a replica server. Skipping this stream."}
    Write-Output "Executing CompressUpdateRevisions"
    if ($AdamjWSUSServerAdminProxy.GetConfiguration().IsReplicaServer -eq $False) { CompressUpdateRevisions } else { Write-Output "This WSUS Server is a Replica Server. You can't compress update revisions from a replica server. Skipping this stream."}
    Write-Output "Executing DeclineSupersededUpdates"
    if ($AdamjWSUSServerAdminProxy.GetConfiguration().IsReplicaServer -eq $False) { DeclineSupersededUpdates -Display -Proceed } else { Write-Output "This WSUS Server is a Replica Server. You can't decline superseded updates from a replica server. Skipping this stream."}
    Write-Output "Executing CleanUpWSUSSynchronizationLogs"
    if ($AdamjCleanUpWSUSSynchronizationLogsAll -eq $True) { CleanUpWSUSSynchronizationLogs -All } else { CleanUpWSUSSynchronizationLogs -ConsistencyNumber $AdamjCleanUpWSUSSynchronizationLogsConsistencyNumber -ConsistencyTime $AdamjCleanUpWSUSSynchronizationLogsConsistencyTime }
    if ($AdamjComputerObjectCleanup -eq $True) { Write-Output "Executing ComputerObjectCleanup" ; ComputerObjectCleanup }
    Write-Output "Executing WSUSDBMaintenance"
    WSUSDBMaintenance
    Write-Output "Executing WSUSServerCleanupWizard"
    WSUSServerCleanupWizard
    CreateAdamjFooter
    AdamjScriptDifferenceInTime
    CreateBodyTXT
    CreateBodyHTML
    if ($AdamjMailReport -eq $True) { MailReport $AdamjMailReportType }
    if ($AdamjSaveReport -eq $True) { SaveReport $AdamjSaveReportType }
}
if ($QuarterlyRun -eq $True) {
    CreateAdamjHeader
    Write-Output "Executing RemoveObsoleteUpdates"
    if ($AdamjWSUSServerAdminProxy.GetConfiguration().IsReplicaServer -eq $False) { RemoveObsoleteUpdates } else { Write-Output "This WSUS Server is a Replica Server. You can't remove obsolete updates from a replica server. Skipping this stream."}
    Write-Output "Executing CompressUpdateRevisions"
    if ($AdamjWSUSServerAdminProxy.GetConfiguration().IsReplicaServer -eq $False) { CompressUpdateRevisions } else { Write-Output "This WSUS Server is a Replica Server. You can't compress update revisions from a replica server. Skipping this stream."}
    Write-Output "Executing DeclineSupersededUpdates"
    if ($AdamjWSUSServerAdminProxy.GetConfiguration().IsReplicaServer -eq $False) { DeclineSupersededUpdates -Display -Proceed } else { Write-Output "This WSUS Server is a Replica Server. You can't decline superseded updates from a replica server. Skipping this stream."}
    Write-Output "Executing CleanUpWSUSSynchronizationLogs"
    if ($AdamjCleanUpWSUSSynchronizationLogsAll -eq $True) { CleanUpWSUSSynchronizationLogs -All } else { CleanUpWSUSSynchronizationLogs -ConsistencyNumber $AdamjCleanUpWSUSSynchronizationLogsConsistencyNumber -ConsistencyTime $AdamjCleanUpWSUSSynchronizationLogsConsistencyTime }
    Write-Output "Executing RemoveWSUSDrivers"
    RemoveWSUSDrivers
    Write-Output "Executing RemoveDeclinedWSUSUpdates"
    RemoveDeclinedWSUSUpdates -Display -Proceed
    if ($AdamjComputerObjectCleanup -eq $True) { Write-Output "Executing ComputerObjectCleanup" ; ComputerObjectCleanup }
    Write-Output "Executing WSUSDBMaintenance"
    WSUSDBMaintenance
    Write-Output "Executing WSUSServerCleanupWizard"
    WSUSServerCleanupWizard
    CreateAdamjFooter
    AdamjScriptDifferenceInTime
    CreateBodyTXT
    CreateBodyHTML
    if ($AdamjMailReport -eq $True) { MailReport $AdamjMailReportType }
    if ($AdamjSaveReport -eq $True) { SaveReport $AdamjSaveReportType }
}
if ($ScheduledRun -eq $True) {
    $DateNow = Get-Date
    CreateAdamjHeader
    if ($AdamjScheduledRunStreamsDay -gt 31 -or $AdamjScheduledRunStreamsDay -eq 0) { Write-Output 'You failed to set a valid value for $AdamjScheduledRunStreamsDay. Setting to 31'; $AdamjScheduledRunStreamsDay = 31 }
    if ($AdamjScheduledRunStreamsDay -eq $DateNow.Day) { Write-Output "Executing RemoveObsoleteUpdates"; if ($AdamjWSUSServerAdminProxy.GetConfiguration().IsReplicaServer -eq $False) { RemoveObsoleteUpdates } else { Write-Output "This WSUS Server is a Replica Server. You can't remove obsolete updates from a replica server. Skipping this stream."} }
    if ($AdamjScheduledRunStreamsDay -eq $DateNow.Day) { Write-Output "Executing CompressUpdateRevisions"; if ($AdamjWSUSServerAdminProxy.GetConfiguration().IsReplicaServer -eq $False) { CompressUpdateRevisions } else { Write-Output "This WSUS Server is a Replica Server. You can't compress update revisions from a replica server. Skipping this stream."} }
    Write-Output "Executing DeclineSupersededUpdates"
    if ($AdamjScheduledRunStreamsDay -eq $DateNow.Day) { if ($AdamjWSUSServerAdminProxy.GetConfiguration().IsReplicaServer -eq $False) { DeclineSupersededUpdates -Display -Proceed } else { Write-Output "This WSUS Server is a Replica Server. You can't decline superseded updates from a replica server. Skipping this stream."} } else { if ($AdamjWSUSServerAdminProxy.GetConfiguration().IsReplicaServer -eq $False) { DeclineSupersededUpdates } else { Write-Output "This WSUS Server is a Replica Server. You can't decline superseded updates from a replica server. Skipping this stream."} }
    Write-Output "Executing CleanUpWSUSSynchronizationLogs"
    if ($AdamjCleanUpWSUSSynchronizationLogsAll -eq $True) { CleanUpWSUSSynchronizationLogs -All } else { CleanUpWSUSSynchronizationLogs -ConsistencyNumber $AdamjCleanUpWSUSSynchronizationLogsConsistencyNumber -ConsistencyTime $AdamjCleanUpWSUSSynchronizationLogsConsistencyTime }
    $AdamjScheduledRunQuarterlyMonths.Split(",") | ForEach-Object {
	    if ($_ -eq $DateNow.Month) {
		    if ($_ -eq 2) {
                if ($AdamjScheduledRunStreamsDay -gt 28 -and [System.DateTime]::isleapyear($DateNow.Year) -eq $True) { $AdamjScheduledRunStreamsDay = 29 }
                else { $AdamjScheduledRunStreamsDay = 28 }
		    }
		    if (4,6,9,11 -contains $_ -and $AdamjScheduledRunStreamsDay -gt 30) { $AdamjScheduledRunStreamsDay = 30 }
            if ($AdamjScheduledRunStreamsDay -eq $DateNow.Day) {
			    Write-Output "Executing RemoveWSUSDrivers"
			    RemoveWSUSDrivers
			    Write-Output "Executing RemoveDeclinedWSUSUpdates"
			    RemoveDeclinedWSUSUpdates -Display -Proceed
		    }
	    }
    }
    if ($AdamjComputerObjectCleanup -eq $True) { Write-Output "Executing ComputerObjectCleanup" ; ComputerObjectCleanup }
    Write-Output "Executing WSUSDBMaintenance"
    if ($AdamjScheduledRunStreamsDay -eq $DateNow.Day) { WSUSDBMaintenance } else { WSUSDBMaintenance -NoOutput }
    Write-Output "Executing WSUSServerCleanupWizard"
    WSUSServerCleanupWizard
    CreateAdamjFooter
    AdamjScriptDifferenceInTime
    CreateBodyTXT
    CreateBodyHTML
    if ($AdamjMailReport -eq $True) { MailReport $AdamjMailReportType }
    if ($AdamjSaveReport -eq $True) { SaveReport $AdamjSaveReportType }
}

if ($DailyRun -eq $True) {
    CreateAdamjHeader
    Write-Output "Executing DeclineSupersededUpdates"
    if ($AdamjWSUSServerAdminProxy.GetConfiguration().IsReplicaServer -eq $False) { DeclineSupersededUpdates } else { Write-Output "This WSUS Server is a Replica Server. You can't decline superseded updates from a replica server. Skipping this stream."}
    Write-Output "Executing CleanUpWSUSSynchronizationLogs"
    if ($AdamjCleanUpWSUSSynchronizationLogsAll -eq $True) { CleanUpWSUSSynchronizationLogs -All } else { CleanUpWSUSSynchronizationLogs -ConsistencyNumber $AdamjCleanUpWSUSSynchronizationLogsConsistencyNumber -ConsistencyTime $AdamjCleanUpWSUSSynchronizationLogsConsistencyTime }
    if ($AdamjComputerObjectCleanup -eq $True) { Write-Output "Executing ComputerObjectCleanup" ; ComputerObjectCleanup }
    Write-Output "Executing WSUSDBMaintenance"
    WSUSDBMaintenance -NoOutput
    Write-Output "Executing WSUSServerCleanupWizard"
    WSUSServerCleanupWizard
    CreateAdamjFooter
    AdamjScriptDifferenceInTime
    CreateBodyTXT
    CreateBodyHTML
    if ($AdamjMailReport -eq $True) { MailReport $AdamjMailReportType }
    if ($AdamjSaveReport -eq $True) { SaveReport $AdamjSaveReportType }
}

if (-not $FirstRun -and -not $MonthlyRun -and -not $QuarterlyRun -and -not $ScheduledRun -and -not $DailyRun) {
    Write-Verbose "All pre-defined routines (-FirstRun, -DailyRun, -MonthlyRun, -QuarterlyRun, -ScheduledRun) were not specified"
    CreateAdamjHeader
    if ($RemoveWSUSDriversSQL -eq $True) { Write-Output "Executing RemoveWSUSDrivers using SQL"; RemoveWSUSDrivers -SQL }
    if ($RemoveWSUSDriversPS -eq $True) { Write-Output "Executing RemoveWSUSDrivers using Powershell"; RemoveWSUSDrivers }
    if ($RemoveObsoleteUpdates -eq $True) { Write-Output "Executing RemoveObsoleteUpdates using SQL"; if ($AdamjWSUSServerAdminProxy.GetConfiguration().IsReplicaServer -eq $False) { RemoveObsoleteUpdates } else { Write-Output "This WSUS Server is a Replica Server. You can't remove obsolete updates from a replica server. Skipping this stream." } }
    if ($CompressUpdateRevisions -eq $True) { Write-Output "Executing CompressUpdateRevisions using SQL"; if ($AdamjWSUSServerAdminProxy.GetConfiguration().IsReplicaServer -eq $False) { CompressUpdateRevisions } else { Write-Output "This WSUS Server is a Replica Server. You can't compress update revisions from a replica server. Skipping this stream." } }
    if ($RemoveDeclinedWSUSUpdates -eq $True) { Write-Output "Executing RemoveDeclinedWSUSUpdates"; RemoveDeclinedWSUSUpdates -Display -Proceed }
    if ($WSUSDBMaintenance -eq $True) { Write-Output "Executing WSUSDBMaintenance"; WSUSDBMaintenance }
    if ($DeclineSupersededUpdates -eq $True) { Write-Output "Executing DeclineSupersededUpdates"; if ($AdamjWSUSServerAdminProxy.GetConfiguration().IsReplicaServer -eq $False) { DeclineSupersededUpdates -Display -Proceed } else { Write-Output "This WSUS Server is a Replica Server. You can't decline superseded updates from a replica server. Skipping this stream." } }
    if ($CleanUpWSUSSynchronizationLogs -eq $True) { Write-Output "Executing CleanUpWSUSSynchronizationLogs"; if ($AdamjCleanUpWSUSSynchronizationLogsAll -eq $True) { CleanUpWSUSSynchronizationLogs -All } else { CleanUpWSUSSynchronizationLogs -ConsistencyNumber $AdamjCleanUpWSUSSynchronizationLogsConsistencyNumber -ConsistencyTime $AdamjCleanUpWSUSSynchronizationLogsConsistencyTime } }
    if ($ComputerObjectCleanup -eq $True -and $AdamjComputerObjectCleanup -eq $True) { Write-Output "Executing ComputerObjectCleanup" ; ComputerObjectCleanup }
    if ($WSUSServerCleanupWizard -eq $True) { Write-Output "Executing WSUSServerCleanupWizard"; WSUSServerCleanupWizard }
    CreateAdamjFooter
    AdamjScriptDifferenceInTime
    CreateBodyTXT
    CreateBodyHTML
    if ($SaveReport -eq "TXT") { SaveReport }
    if ($SaveReport -eq "HTML") { SaveReport -ReportType "HTML" }
    if ($MailReport -eq "HTML") { MailReport }
    if ($MailReport -eq "TXT") { MailReport -MessageContentType "TXT" }
}

if ($HelpMe -eq $True) {
    HelpMe
}
if ($DisplayApplicationPoolMemory -eq $True) {
    ApplicationPoolMemory
}
if ($IncreaseApplicationPoolMemory) {
    ApplicationPoolMemory -IncreaseApplicationPoolBy $IncreaseApplicationPoolMemory
}

#endregion ProcessTheFunctions
<#
# All Possible Function Calls

CreateAdamjHeader
RemoveWSUSDrivers -SQL
    RemoveWSUSDriversSQL
    RemoveWSUSDriversPS
RemoveDeclinedWSUSUpdates -Display -Proceed
    RemoveDeclinedWSUSUpdatesProceed
    RemoveDeclinedWSUSUpdatesDisplayUpdates
    RemoveDeclinedWSUSUpdatesCountUpdates
CompressUpdateRevisions
RemoveObsoleteUpdates
WSUSDBMaintenance -NoOutput
DeclineSupersededUpdates -Display -Proceed
    DeclineSupersededUpdatesProceed
    DeclineSupersededUpdatesDisplayUpdates
    DeclineSupersededUpdatesCountUpdates
CleanUpWSUSSynchronizationLogs -ConsistencyNumber "14" -ConsistencyTime "Day" -All
ComputerObjectCleanup
WSUSServerCleanupWizard
CreateAdamjFooter
CreateBodyTXT
CreateBodyHTML
SaveReport -ReportType
MailReport -MessageContentType
HelpMe
ApplicationPoolMemory -IncreaseApplicationPoolBy 1024
Install-Task
#>
}

End {
    if ($HelpMe -eq $True) { $VerbosePreference = $AdamjOldVerbose; Stop-Transcript }
    Write-Verbose "End Of Code"
}
################################
#         End Of Code          #
################################
#EOF