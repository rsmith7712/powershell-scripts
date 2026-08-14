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
    Validate-Patching.ps1

.NOTES
    Name: Get-WSUSReport
    Author: Scott Babcock
.SYNOPSIS
    Gets WSUS information for a specific group and genreates an HTML email report.
.DESCRIPTION
    The script Get-WSUSReport loads the WSUS assembly and makes a connection to 
    the WSUS server in your environment. It targets a specific group and checks
    for the status of updates on each server within the group.  The HTML report
    lists a table of updates per server and a second table of servers per update.
.EXAMPLE  
    [PS] C:\>.\Get-WsusReport.ps1 <no parameters>
    The script does not have any parameters.

.FUNCTIONALITY
    The script Get-WSUSReport loads the WSUS assembly and makes a connection to
        the WSUS server in your environment. It targets a specific group and checks
        for the status of updates on each server within the group.  The HTML report
        lists a table of updates per server and a second table of servers per update.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

############################################# Initializations
$script:script_filepath = $MyInvocation.MyCommand.Path
$script:script_dir = Split-Path -Parent $script:script_filepath
$ErrorActionPreference = "SilentlyContinue"
$Script:wsusServer = "SRV-WSUS-APP1"
$Script:ExportDir = "\\SERVER\SHARE\...\wsusScratchDir"
$FQDN = "example.com"

############################################# Functions
Function Choose-Group
{
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
            "Quits the script."
    
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($Pilot,$Group1,$Group2,$DMZ,$Quit)
    
        $Group = $host.ui.PromptForChoice($title, $message, $options, 4)
    }
    
    Switch ($Group)
    {
        0{Return "Server Pilot"}
        1{Return "Server Systems"}
        2{Return "Server Systems 2"}
        3{Return "DMZ Servers"}
        4{Write-Host "You've chosen to cancel the script.";Exit 1}
        default{Write-Host "You've entered a non-existant Server Group. Script exiting in 5 seconds.";Start-Sleep 5;Exit 1}
    }
}

############################################# Script Start
# Create empty arrays.
$UpdateStatus = @()
$SummaryStatus = @()
$ServersPerUpdate = @()
 
# Load WSUS assembly.
[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | Out-Null
# Connect to WSUS server and set the connection object into a variable.
If($ENV:COMPUTERNAME -eq $wsusServer)
{
    $wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer()
}
Else
{            
    $wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($Script:wsusServer,$False,8530)
}
If(!($?))
{
    Write-Host "This system doesn't have the WSUS console installed. Either install the console or run this script directly on $($wsusServer)"
    Exit 1
}
# Record the last time that WSUS was syncronized with updates.
$LastSync = ($wsus.GetSubscription()).LastSynchronizationTime
 
# Create a default update scope object.
$UpdateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
# Modify the update scope ApprovedStates value from "Any" to "LatesRevisionApproved".
$UpdateScope.ApprovedStates = [Microsoft.UpdateServices.Administration.ApprovedStates]::LatestRevisionApproved
# Create a computerscope object for use as an a requred part of a method below.
$ComputerScope = New-Object Microsoft.UpdateServices.Administration.ComputerTargetScope

# Get Server Group
$Group = Choose-Group

# Get the "Servers" WSUS group using a hardcoded ID value.
$ComputerTargetGroups = $WSUS.GetComputerTargetGroups() `
| Where-Object { $_.name -eq $Group }
# Get all the computers objects that are members of the "Servers" group and set into variable
$MemberOfGroup = $wsus.getComputerTargetGroup($ComputerTargetGroups.Id).GetComputerTargets()
 
# Use a foreach loop to process summaries per computer for each member of the "Servers" group. `
#  Then populate an array with a updates needed.
Foreach ($Object in $wsus.GetSummariesPerComputerTarget($updatescope, $computerscope)) {
	# Use a nested foreach to process the CES Mail Servers members.	
	foreach ($object1 in $MemberOfGroup) {
		# Use an if statement to match the wsus objects that contain update summaries with
		#  the members of the CES Mail servers members.
		If ($object.computertargetid -match $object1.id) {
			# Set the fulldomain name of the CES Mail Server member in a variable.
			$ComputerTargetToUpdate = $wsus.GetComputerTargetByName($object1.FullDomainName)
			# Filter the server for updates that are marked for install with the state
			#  being either downloaded or notinstalled.  These are updates that are needed.
			$NeededUpdate = $ComputerTargetToUpdate.GetUpdateInstallationInfoPerUpdate() `
			| where-object {
				($_.UpdateApprovalAction -eq "install") -and `
				(($_.UpdateInstallationState -eq "downloaded") -or `
				($_.UpdateInstallationState -eq "notinstalled"))
			}
			
			# Null out the following variables so that they don't contaminate
			#  op_addition variables in the below nested foreach loop.
			$FailedUpdateReport = $null
			$NeededUpdateReport = $null
			# Use a nested foreach loop to accumulate and convert the needed updates to the KB number with URL in
			# an HTML format.
			if ($NeededUpdate -ne $null) {
				foreach ($Update in $NeededUpdate) {
					$myObject2 = New-Object -TypeName PSObject
					$myObject2 | add-member -type Noteproperty -Name Server -Value (($object1 | select-object -ExpandProperty FullDomainName) -replace ".$($FQDN)", "")
					$myObject2 | add-member -type Noteproperty -Name Update -Value ('<a href' + '=' + '"' + ($wsus.GetUpdate([Guid]$update.updateid).AdditionalInformationUrls) + '"' + '>' + (($wsus.GetUpdate([Guid]$update.updateid)).title) + '<' + '/' + 'a' + '>')
					$UpdateStatus += $myObject2
					
					if ($Update.UpdateInstallationState -eq "Failed") {
						$FailedUpdateReport += ('<a href' + '=' + '"' + ($wsus.GetUpdate([Guid]$update.updateid).AdditionalInformationUrls) `
						+ '"' + '>' + "(" + (($wsus.GetUpdate([Guid]$update.updateid)).KnowledgebaseArticles) + ") " + '<' + '/' + 'a' + '>')
					}
					if ($Update.UpdateInstallationState -eq "Notinstalled" -or $Update.UpdateInstallationState -eq "Downloaded") {
						$NeededUpdateReport += ('<a href' + '=' + '"' + ($wsus.GetUpdate([Guid]$update.updateid).AdditionalInformationUrls) `
						+ '"' + '>' + "(" + (($wsus.GetUpdate([Guid]$update.updateid)).KnowledgebaseArticles) + ") " + '<' + '/' + 'a' + '>')
					}
				}
			}
			# Create a custom PSObject to contain summary data about each server and updates needed.
			$myObject1 = New-Object -TypeName PSObject
			$myObject1 | add-member -type Noteproperty -Name Server -Value (($object1 | select-object -ExpandProperty FullDomainName) -replace ".$($FQDN)", "")
			$myObject1 | add-member -type Noteproperty -Name UnkownCount -Value $object.UnknownCount
			$myObject1 | add-member -type Noteproperty -Name NotInstalledCount -Value $object.NotInstalledCount
			$myObject1 | add-member -type Noteproperty -Name NotApplicable -Value $object.NotApplicableCount
			$myObject1 | add-member -type Noteproperty -Name DownloadedCount -Value $object.DownloadedCount
			$myObject1 | add-member -type Noteproperty -Name InstalledCount -Value $object.InstalledCount
			$myObject1 | add-member -type Noteproperty -Name InstalledPendingRebootCount -Value $object.InstalledPendingRebootCount
			$myObject1 | add-member -type Noteproperty -Name FailedCount -Value $object.FailedCount
			$myObject1 | add-member -type Noteproperty -Name ComputerTargetId -Value $object.ComputerTargetId
			$myObject1 | add-member -type Noteproperty -Name NeededCount -Value ($NeededUpdate | measure-object).count
			$myObject1 | add-member -type Noteproperty -Name Failed -Value $FailedUpdateReport
			$myObject1 | add-member -type Noteproperty -Name Needed -Value $NeededUpdateReport
			$SummaryStatus += $myObject1
		}
	}
}
$uniqueupdates = $UpdateStatus | sort-object -Unique update | select-object update
 
foreach ($uniqueupdate in $uniqueupdates) {
	$servers = $null
	$myObject3 = New-Object -TypeName PSObject
	$myObject3 | add-member -type Noteproperty -Name Update -Value $uniqueupdate.update
	foreach ($object in $UpdateStatus) {
		if ($object.Update -eq $uniqueupdate.update) {
			$servers += $object.server + " "
		}
	}
	$myObject3 | add-member -type Noteproperty -Name Servers -Value $servers
	$ServersPerUpdate += $myObject3
}
 
# Rewrite the array and eliminate servers that have 0 for needed updates.
$SummaryStatus = $SummaryStatus | where-object { $_.neededcount -ne 0 } | sort-object server
 
# List a summary of changes in a special table leveraging the "First" table class style listed above.
$WSUSHead += "<table class=`"First`">`r`n"
# Note the LastSync time.
$WSUSHead += "<tr><td class=`"First`"><b>Last Sync:</b></td><td class=`"First`"> " + `
$LastSync + "</td></tr>`r`n"
$WSUSHead += "</Body>`r`n"
$WSUSHead += "</Style>`r`n"
$WSUSHead += "</Head>`r`n"
 
# Create a generic HTML Header to use throughout the script for the body of the `
#  email message with table styles to control the formatting of any tables present it it.
$HTMLHead = "<Html xmlns=`"http://www.w3.org/1999/xhtml`">`r`n"
$HTMLHead += "<Head>`r`n"
$HTMLHead += "<Style>`r`n"
$HTMLHead += "TABLE{border: 1px solid black; border-collapse: collapse; font-family: Arial, Helvetica, sans-serif; font-size: 8pt;}`r`n"
$HTMLHead += "TH{border: 1px solid black; background: #dddddd; padding: 5px; color: #000000;}`r`n"
$HTMLHead += "TD{border: 1px solid black; padding: 5px;}`r`n"
$HTMLHead += "TABLE.First{border:1px solid #dddddd; background: #f6f6f6;}`r`n"
$HTMLHead += "TD.First{border:1px solid #dddddd; font-family: Arial, Helvetica, sans-serif; font-size: 8pt;}`r`n"
$HTMLHead += "H3{text-align:left; font-family: Arial, Helvetica, sans-serif; font-size: 15pt;}`r`n"
$HTMLHead += "HR{border: 2px dashed #848484;}`r`n"
$HTMLHead += "</Style>`r`n"
$HTMLHead += "</Head>`r`n"
 
# Build a variable with HTML for sending a report.
$UpdatesHTML = $HTMLHead
# Continue building HTML with the updates needed
$UpdatesHTML += $SummaryStatus | convertto-html -Fragment `
@{ Label = "Server"; Expression = { $_.server } }, @{ Label = "Needed Count"; Expression = { $_.NeededCount } }, @{ Label = "Not Installed"; Expression = { $_.NotInstalledCount } }, `
@{ Label = "Downloaded"; Expression = { $_.DownloadedCount } }, @{ Label = "Pending Reboot"; Expression = { $_.InstalledPendingRebootCount } }, @{ Label = "Failed Updates"; Expression = { $_.FailedCount } }, `
@{ Label = "Needed"; Expression = { $_.Needed } }
 
$ServersHTML = $ServersPerUpdate | convertto-html -Fragment `
@{ Label = "Update"; Expression = { $_.update } }, @{ Label = "Servers"; Expression = { $_.servers } }
 
# Add an assembly to fix up powershell HTML markup. Ensures all special characters
# are converted correctly.
Add-Type -AssemblyName System.Web
$UpdatesHTML = [System.Web.HttpUtility]::HtmlDecode($UpdatesHTML)
$ServersHTML = [System.Web.HttpUtility]::HtmlDecode($ServersHTML)
 
# Create HTML email by adding all the various HTML sections from above.
$MailMessage = "
<html>
 <body>
  $WSUSHead
  $UpdatesHTML
   <br>
  $ServersHTML
 </body>
</html>
"
 
# Get the date and time.
$DateTime = Get-Date -Format "ddd MM/dd/yyyy h:mm tt"
# Set subject line to include the $DateTime variable.
$EmailSubject = "Update Status for " + $DateTime
 
# Send an email with all the compiled data.
[string[]]$EmailTo = "user4@example.com"
Send-MailMessage -To $EmailTo `
-Subject $EmailSubject -From "donotreply@example.com" `
-Body $MailMessage -BodyasHTML `
-SmtpServer "smpti.example.com"

$MailMessage | Out-File C:\temp\Test.html