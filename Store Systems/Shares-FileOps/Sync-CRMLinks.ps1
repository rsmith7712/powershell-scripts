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
    Sync-CRMLinks.ps1

.DESCRIPTION
    Deploys the FUNDrive website and CRM shortcuts to a prompted target computer.

.FUNCTIONALITY
    Deploys FUNDrive and CRM shortcuts.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#Naming Variables

#$computers = Get-Content \\SERVER\SHARE\...\TestList.txt
$computers = Read-host "Target Computer:"

$fundrivewebname = "FUNDrive Website.lnk"
$fundrivecrmname = "FUNDrive CRM.lnk"

$fundriveweburl = "https://fundrive.example.com"
$fundrivecrmurl = "https://domain.crm.dynamics.com"

#Copy Icons to target machines
foreach ($computer in $computers) {
    Copy-Item -path \\SERVER\SHARE\...\fundrive.ico -destination \\$computer\C$\...\fundrive.ico -Force
    }
foreach ($computer in $computers) {
    Copy-Item -path \\SERVER\SHARE\...\crm.ico -destination \\$computer\C$\...\crm.ico -Force
    }

#create shortcut for Fundrive Website

function create-shortcutweb {
    foreach ($computer in $computers) {
        $shortcutpath = "\\$computer\C$\...\start menu\$fundrivewebname"
        $wscriptshell = New-Object -ComObject wscript.shell
        $shortcut = $wscriptshell.CreateShortcut($shortcutpath)
        $shortcut.TargetPath = "C:\Program Files (x86)\Internet Explorer\iexplore.exe"
        $shortcut.IconLocation = "C:\windows\system32\fundrive.ico,0"
        $shortcut.Arguments = $fundriveweburl
        $shortcut.Save()
        }
    }

#create shortcut for Fundrive CRM

function create-shortcutcrm {
    foreach ($computer in $computers) {
        $shortcutpath = "\\$computer\C$\...\start menu\$fundrivecrmname"
        $wscriptshell = New-Object -ComObject wscript.shell
        $shortcut = $wscriptshell.CreateShortcut($shortcutpath)
        $shortcut.TargetPath = "C:\Program Files (x86)\Internet Explorer\iexplore.exe"
        $shortcut.IconLocation = "C:\windows\system32\crm.ico,0"
        $shortcut.Arguments = $fundrivecrmurl
        $shortcut.Save()
        }
    }

#Verify file creation

function verify-fileweb {
    foreach ($computer in $computers) {
        $file = "\\site\C$\...\start menu\Fundrive Website.lnk"
        $ValidPath = Test-Path $file -IsValid
        if ($ValidPath -eq $true) {Write-host "$computer - Web Link Deployed"}
        Else {Write-Host "$computer - Web Link Deployment Failed"}
        }
    }

function verify-filecrm {
    foreach ($computer in $computers) {
        $file = "\\site\C$\...\start menu\Fundrive CRM.lnk"
        $ValidPath = Test-Path $file -IsValid
        if ($ValidPath -eq $true) {Write-host "$computer - CRM Link Deployed"}
        Else {Write-Host "$computer - CRM Link Deployment Failed"}
        }
    }

#Deploy Shortcuts

create-shortcutweb
create-shortcutcrm
verify-fileweb | format-list | Out-File C:\Weblink.txt
verify-filecrm | format-list | Out-File C:\crmlink.txt