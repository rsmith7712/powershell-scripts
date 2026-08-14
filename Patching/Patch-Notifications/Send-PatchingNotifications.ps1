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
    Send-PatchingNotifications.ps1

    .SYNOPSIS
    Sends out updated email template for Patching
    
    .DESCRIPTION
    After allowing user to select patch groups, script gets servers in those patch groups
        directly from WSUS and send a templated email to sysadmins@example.com for distribution.
    
    .NOTES
    Version:        1.0
    Author:         user4@example.com
    Creation Date:  10/04/17
    Purpose/Change: Fixed a small issue in the HTML build process. Ready for production use.

    .HISTORY
    Version:        0.2 (10/04/17)
    Purpose/Change: Made it work.
    Version:        0.1
    Purpose/Change: Initial script creation

.FUNCTIONALITY
    After allowing user to select patch groups, script gets servers in those patch groups
            directly from WSUS and send a templated email to sysadmins@example.com for distribution.

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
        0{Return "00_servers"}
        1{Return "01_servers"}
        2{Return "02_servers"}
        3{Return "DMZ Servers"}
        4{Write-Host "You've chosen to cancel the script.";Exit 1}
        default{Write-Host "You've entered a non-existant Server Group. Script exiting in 5 seconds.";Start-Sleep 5;Exit 1}
    }
}

Function Prompt-Additional
{
    If([string]::IsNullOrEmpty($Script:ServerGroup))
    {
        $title = "Additional Groups"
        $message = "Would You Like to Add Another Group?"
    
        $Pilot = New-Object System.Management.Automation.Host.ChoiceDescription "Server &Pilot", `
            "Checks the services of all servers in the Pilot group."
    
        $Group1 = New-Object System.Management.Automation.Host.ChoiceDescription "Server Group&1", `
            "Checks the services of all servers in Group1."
    
        $Group2 = New-Object System.Management.Automation.Host.ChoiceDescription "Server Group&2", `
            "Checks the services of all servers in Group2."
    
        $DMZ = New-Object System.Management.Automation.Host.ChoiceDescription "&DMZ", `
            "Checks the services of all servers in the DMZ."
        
        $Quit = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
            "Declines to add an additional group."
    
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($Pilot,$Group1,$Group2,$DMZ,$Quit)
    
        $AddGroup = $host.ui.PromptForChoice($title, $message, $options, 4)
    }
    Switch ($AddGroup)
    {
        0{Return "00_servers"}
        1{Return "01_servers"}
        2{Return "02_servers"}
        3{Return "DMZ Servers"}
        4{Return $NULL}
        default{Write-Host "You've entered a non-existant Server Group. Script exiting in 5 seconds.";Start-Sleep 5;Exit 1}
    }
}

Function Get-WSUSGroup($Group)
{
    # Imports Server List from WSUS
    # http://techibee.com/powershell/find-list-of-computerstargets-in-a-wsus-group-using-powershell/2139
    [void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
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
    #$wsus.GetComputerTargetGroups()
    $mygroup = $wsus.GetComputerTargetGroups() | Where-Object {$_.Name -eq $Group}
    $wsusImport = $mygroup.GetComputerTargets() | Select-Object -ExpandProperty FullDomainName
    $wsusImport = $wsusImport | ForEach-Object{$_.Split(".") | Select-Object -First 1} #Removes FQDN, for testing.
    Return $wsusImport
}

Function Modify-HTML($Template)
{
    New-Item -Path $Script:ExportDir -Name HTML -Type Directory -Force
    Copy-Item "\\SERVER\SHARE\...\PatchingEmailTemplate.html" -Destination "$Script:ExportDir\HTML"
    $HTML = "$Script:ExportDir\HTML\PatchingEmailTemplate.html"
    $Short = Get-Saturday "Short"
    (Get-Content $HTML).replace('SHORTDATE', $Short) | Set-Content $HTML
    $Long = Get-Saturday "Long"
    (Get-Content $HTML).replace('LONGDATE', $Long) | Set-Content $HTML
}

Function Clean-ScratchDir
{
    Get-ChildItem -Path $Script:ExportDir -Include *.* -File -Recurse | ForEach-Object { $_.Delete()}
}

Function Get-Saturday($Length)
{
    $Date = @(@(0..7) | % {$(Get-Date).AddDays($_)} | ? {$_.DayOfWeek -ieq "Wednesday"})[0]
    Switch($Length)
    {
        "Short"{$Date = $Date.ToString("MM/dd/yyyy")}
        "Long"{$Date = $Date.ToString("D")}
    }
    Return $Date
}

Function Send-Email()
{
    Modify-HTML
    $Date = Get-Saturday "Short"
	$To = "sysadmins@example.com"
    $From = "WSUS Email Template <wsus_email_template@example.com>"
    $smtphost = "smtpi.example.com"
    $subject = "Scheduled Server Patching - $($Date)"
    $body = Get-Content "$Script:ExportDir\HTML\PatchingEmailTemplate.html"
    $smtp = New-Object System.Net.Mail.SmtpClient $smtphost
    $msg = New-Object System.Net.Mail.MailMessage $from, $to, $subject, $body
    $InlineImage = Add-Inline
    $msg.Attachments.Add($InlineImage)
    Get-ChildItem -Path $Script:ExportDir | ForEach-Object {$Att = New-Object System.Net.Mail.Attachment -ArgumentList "$Script:ExportDir\$_";$msg.Attachments.Add($Att)}
    $msg.isBodyhtml = $true
    $smtp.send($msg)
}

Function Add-Inline
{
    $attachment = New-Object System.Net.Mail.Attachment -ArgumentList "\\SERVER\SHARE\...\image001.png" #convert file-system object type to string
    $attachment.ContentDisposition.Inline = $True
    $attachment.ContentDisposition.DispositionType = "Inline"
    $attachment.ContentType.MediaType = "image/png"
    $attachment.ContentId = "image001.png"
    Return $attachment
}

############################################# Script Start
$ServerGroups = @()
Clear-Host
Start-Sleep 2
$ServerGroups += Choose-Group
Start-Sleep 2
Clear-Host
Start-Sleep 2
$PromptResponse = Prompt-Additional
If($PromptResponse -ne $NULL)
{
    $ServerGroups += $PromptResponse
}

# Wipes old entries from the scratch directory
Clean-ScratchDir

ForEach($Group in $ServerGroups)
{
    $TextExport = Get-WSUSGroup $Group
    $TextExport | Out-File "$ExportDir\$Group.txt"
}

Send-Email