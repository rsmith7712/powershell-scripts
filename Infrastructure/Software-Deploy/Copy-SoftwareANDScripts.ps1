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
    Copy-SoftwareANDScripts.ps1

.DESCRIPTION
    Maps a software-delivery share using a service credential and copies software and scripts to local C:\SOFTWARE and C:\SCRIPTS folders.

.FUNCTIONALITY
    Copies software and scripts from a share to local folders.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$username = "domain\ADMAdmin"
$password = ConvertTo-SecureString '<password>' -AsPlainText -Force
$credential = New-Object system.management.automation.pscredential($username,$password)

$drive = New-PSDrive -Name "P" -PSProvider FileSystem -Root "\\SERVER\SHARE\...\STJS" -Credential $credential -Persist

if(!(Test-Path "C:\SOFTWARE"))
{
    New-Item -Path "C:\SOFTWARE" -ItemType Directory
}

if(!(Test-Path "C:\SCRIPTS"))
{
    New-Item -Path "C:\SCRIPTS" -ItemType Directory
}

$folders = (Get-ChildItem "P:").Name


foreach($folder in $folders)
{
    Copy-Item -Path "P:\$($folder)" -Destination "C:\" -Recurse -Force
}

Copy-Item -Path "C:\temp\Setup.lnk" -Destination "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\Setup.lnk" -Force

Remove-PSDrive $drive