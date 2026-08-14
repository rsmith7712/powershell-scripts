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
    powerCLI_GetSnapshots.ps1

.SYNOPSIS
    Simple HTML report showing all snapshots on your VMware vSphere
    environment
.DESCRIPTION
    Run this script to produce a simple HTML report showing all the 
    snapshots in your vSphere environment.  This script is designed to
    run without prompting you for credentials, saving the password in
    a (mostly) secure, encrypted file.  You must run the script once 
    manually to produce the proper credential file before putting it 
    into a scheduled task.
    
    You must modify the $Key variable below to get unique encryption, 
    otherwise anyone who downloads this script would have the same encryption 
    key you do!
    
    Credit to Daniel for the idea of using a unique key value in the
    ConvertTo-SecureString cmdlet allowing multiple computers to use this
    credential file.
    LINK: http://poshcode.org/3752
    
    Requires VMware PowerCLI be installed.
    
    *** IMPORTANT ***
    Required:  Modify the $Key variable to get unique encryption on your
    credentials.
    
    Idea for the unique
.PARAMETER VIServer
    Name of your vSphere vCenter server, or the name of your ESXi host.
.PARAMETER Admin
    Name of the administrative account needed to authenticate to vSphere.
.PARAMETER PathToCredentials
    Path where the script will save the credential file.
.PARAMETER PathToReport
    Path where the HTML report will be saved.
.PARAMETER To
    Who the emailed report is going to
.PARAMETER From
    Who the emailed report is coming from
.PARAMETER SMTPServer
    The IP address or name of the SMTP relay you want to use
.EXAMPLE
    .\Report-Snapshots.ps1 -VIServer VCenter1 -Admin Administrator -PathToCredentials \\server\share\cred -PathToReport \\server\share\reports
	
.\powerCLI_GetSnapshots.ps1 -VIServer DomainVC1.example.com -Admin DOMAIN\sysadmin -PathToCredentials C:\scripts -PathToReport C:\temp
    
    Create a report of all the snapshots of VM's under the control of the
    VCenter1 vCenter server.  You will authenticate using the Administrator
    account and save the credential file on "server", in the share called
    "share" and the directory "cred".  The resulting HTML report will be
    saved on the same server and share, but in the directory "reports".
.EXAMPLE
    .\Report-Snapshots.ps1 -VIServer VCenter1 -Admin Administrator -PathToCredentials \\server\share\cred -PathToReport \\server\share\reports -To "me@myexample.com" -From "you@yourexample.com" -SMTPServer "MyExchange1"
    
.\powerCLI_GetSnapshots.ps1 -VIServer DomainVC1.example.com -Admin DOMAIN\sysadmin -PathToCredentials C:\scripts -PathToReport C:\temp -To "admin2@example.com" -From "powerCLI@example.com" -SMTPServer "smtpi@example.com"
	
    Same as the example above, but overriding the default mailing parameters
    to send to me@myexample.com, from you@yourexample.com and using the MyExchange1
    server to relay the email.

.OUTPUTS
    HTML Report:  SnapshotReport.HTML
.NOTES
    Author:            Martin Pugh
    Key Idea:          Daniel (http://poshcode.org/3752)
    Twitter:           @thesurlyadm1n
    Spiceworks:        Martin9700
    Blog:              www.thesurlyadmin.com

.LINK
    http://community.spiceworks.com/scripts/show/1871-vm-snapshot-report
.LINK
    http://poshcode.org/3752

.FUNCTIONALITY
    Run this script to produce a simple HTML report showing all the
        snapshots in your vSphere environment.  This script is designed to
        run without prompting you for credentials, saving the password in
        a (mostly) secure, encrypted file.  You must run the script once
        manually to produce the proper credential file before putting it
        into a scheduled task.

        You must modify the $Key variable below to get unique encryption,
        otherwise anyone who downloads this script would have the same encryption
        key you do!

        Credit to Daniel for the idea of using a unique key value in the
        ConvertTo-SecureString cmdlet allowing multiple computers to use this
        credential file.
        LINK: http://poshcode.org/3752

        Requires VMware PowerCLI be installed.

        *** IMPORTANT ***
        Required:  Modify the $Key variable to get unique encryption on your
        credentials.

        Idea for the unique

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Param (
    [Alias("Host")]
    [string]$VIServer = "DomainVC1.example.com",
    [string]$Admin = "DOMAIN\sysadmin",
    [string]$PathToCredentials = "C:\temp\",
    [string]$PathToReport = "C:\temp\",
    
    [string]$To = "admin2@example.com",
    [string]$From = "vmreports@example.com",
    [string]$SMTPServer = "smtpi.example.com"
)

#You must change these values to securely save your credential files
$Key = [byte]57,86,30,29,72,75,85,52,73,33,0,21,56,76,99,13

#region Functions

Function Get-Credentials {
    Param (
	    [String]$AuthUser = $env:USERNAME,
        [string]$PathToCred
    )

    #Build the path to the credential file
    $CredFile = $AuthUser.Replace("\","~")
    If (-not $PathToCred)
    {
        $PathToCred = Split-Path $MyInvocation.MyCommand.Path
    }
    $File = Join-Path -Path $PathToCred -ChildPath "\Credentials-$CredFile.crd"
	#And find out if it's there, if not create it
    If (-not (Test-Path $File))
	{	(Get-Credential $AuthUser).Password | ConvertFrom-SecureString -Key $Key | Set-Content $File
    }
	#Load the credential file 
    $Password = Get-Content $File | ConvertTo-SecureString -Key $Key
    $AuthUser = (Split-Path $File -Leaf).Substring(12).Replace("~","\")
    $AuthUser = $AuthUser.Substring(0,$AuthUser.Length - 4)
	$Credential = New-Object System.Management.Automation.PsCredential($AuthUser,$Password)
    Return $Credential
}


Function Set-AlternatingRows {
    [CmdletBinding()]
         Param(
             [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
             [object[]]$HTMLDocument,
      
             [Parameter(Mandatory=$True)]
             [string]$CSSEvenClass,
      
             [Parameter(Mandatory=$True)]
             [string]$CSSOddClass
         )
     Begin {
         $ClassName = $CSSEvenClass
     }
     Process {
         [string]$Line = $HTMLDocument
         $Line = $Line.Replace("<tr>","<tr class=""$ClassName"">")
         If ($ClassName -eq $CSSEvenClass)
         {    $ClassName = $CSSOddClass
         }
         Else
         {    $ClassName = $CSSEvenClass
         }
         $Line = $Line.Replace("<table>","<table width=""50%"">")
         Return $Line
     }
}


Function Get-SnapshotCreator {
    Param (
        [string]$VM,
        [datetime]$Created
    )

    (Get-VIEvent -Entity $VM -Types Info -Start $Created.AddSeconds(-10) -Finish $Created.AddSeconds(10) | Where FullFormattedMessage -eq "Task: Create virtual machine snapshot" | Select -ExpandProperty UserName).Split("\")[-1]
}
#endregion

If (-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue))
{   Try { Add-PSSnapin VMware.VimAutomation.Core -ErrorAction Stop }
    Catch { Throw "Problem loading VMware.VimAutomation.Core snapin because ""$($Error[1])""" }
}

If (-not $PathToCredentials)
{
    $PathToCredentials = Split-Path $MyInvocation.MyCommand.Path
}

If (-not $PathToReport)
{
    $PathToReport = Split-Path $MyInvocation.MyCommand.Path
}

$Cred = Get-Credentials $Admin $PathToCredentials
Try {
    $Conn = Connect-VIServer $VIServer -Credential $Cred -ErrorAction Stop 3>$null
}
Catch {
    Throw "Error connecting to $VIServer because ""$($Error[1])"""
}

$Header = @"
<style>
TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TR:Hover TD {Background-Color: #C1D5F8;}
TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #6495ED;}
TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
.odd  { background-color:#ffffff; }
.even { background-color:#dddddd; }
</style>
<title>
Snapshot Report - $VIServer
</title>
"@

$Report = Get-VM | 
    Get-Snapshot | 
    Select VM,
    Name,
    Description,
    @{Name="SizeGB";Expression={ [math]::Round($_.SizeGB,2) }},
    @{Name="Creator";Expression={ Get-SnapshotCreator -VM $_.VM -Created $_.Created }},
    Created,
    @{Name="Days Old";Expression={ (New-TimeSpan -End (Get-Date) -Start $_.Created).Days }}

If (-not $Report)
{   $Report = [PSCustomObject]@{
        VM = "No snapshots found on any VM's controlled by $VIServer"
        Name = ""
        Description = ""
        Size = ""
        Creator = ""
        Created = ""
        'Days Old' = ""
    }
}

$Report = $Report | 
    ConvertTo-Html -Head $Header -PreContent "<p><h2>Snapshot Report - $VIServer</h2></p><br>" | 
    Set-AlternatingRows -CSSEvenClass even -CSSOddClass odd
$Report | Out-File $PathToReport\SnapShotReport.html

$MailSplat = @{
    To         = $To
    From       = $From
    Subject    = "$VIServer Snapshot Report"
    Body       = ($Report | Out-String)
    BodyAsHTML = $true
    SMTPServer = $SMTPServer
}

Send-MailMessage @MailSplat