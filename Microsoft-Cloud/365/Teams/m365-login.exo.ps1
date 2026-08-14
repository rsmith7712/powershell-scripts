# LEGAL
<# LICENSE
    MIT License, Copyright 2017 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
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
    m365-login.exo.ps1

.DESCRIPTION
    Connects PowerShell to Exchange Online using the MFA-enabled sign-in module (CreateExoPSSession).

.FUNCTIONALITY
    Opens an MFA-enabled Exchange Online session.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#Connect PowerShell to Exchange Online (must have Exchange Online Powershell already Installed)

$MFAExchangeModule = ((Get-ChildItem -Path $($env:LOCALAPPDATA+"\Apps\2.0\") -Filter CreateExoPSSession.ps1 -Recurse ).FullName | Select-Object -Last 1) 

 . "$MFAExchangeModule" 

#prompts for MFA login
Connect-EXOPSSession -UserPrincipalName hohadmin@example.com

#Import-PSSession -Session $s -AllowClobber
 
#Import CSV

$list = Import-Csv "C:\temp\text\exouser.csv"


Write-Host "Export current user's configuration " -ForegroundColor Yellow
foreach($entry in $list)
 {
 
$user = $entry.User

Get-CASMailbox -Identity $user | Select-Object displayname, owafordevicesenabled , owaenabled, activesyncenabled | export-csv C:\temp\text\Audit.currentconfig.4.24.20.csv -Append

}


#Disables OWA, Acticesync, OWA for device enable
Write-Host "Disabling Remote Mobile Access for Retail Store mailboxes" -ForegroundColor Yellow 

foreach($entry in $list)
 {
 
$User = $entry.User
 
Set-casmailbox $user -OWAEnabled $False  -ActiveSyncEnabled $False -OWAforDevicesEnabled $False
 
}

Write-Host "Export Audit Report to CSV File " -ForegroundColor Green

foreach($entry in $list)
 {
 
$user = $entry.User

Get-CASMailbox $user | Select-Object displayname, owafordevicesenabled , owaenabled, activesyncenabled | export-csv C:\temp\text\login.exo.audit.4.24.20.csv -Append

}



<# Display without exporting
foreach($entry in $list)
 {
 
$user = $entry.User

Get-CASMailbox -Identity $user | Select-Object displayname, owafordevicesenabled , owaenabled, activesyncenabled

}

#>

#Closes session
#Remove-PSSession -id 1