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
    splunk.ps1

.DESCRIPTION
    Installs the Splunk Universal Forwarder MSI on a prompted remote system.

.FUNCTIONALITY
    Installs the Splunk forwarder on a remote system.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# remoteSplunkInstal.ps1
# 
# Purpose:
# Install MSI packages on remote systems
# 

#Variables
$computername = Read-Host "Enter computer name"
$sourcefile = "\\SERVER\SHARE\...\splunkforwarder-6.4.2-00f5bb3fa822-x64-release.msi"


#This section will install the software 
foreach ($computer in $computername) 
{
$destinationFolder = "\\$computer\C$\SplunkUniversalForwarder"


#This section will copy the $sourcefile to the $destinationfolder. If the Folder does not exist it will create it.

if (!(Test-Path -path $destinationFolder))

{

New-Item $destinationFolder -ItemType Directory

}

Copy-Item -Path $sourcefile -Destination $destinationFolder

Invoke-Command -ComputerName $computer -ScriptBlock { & cmd /c "msiexec.exe /i "splunkforwarder-6.4.2-00f5bb3fa822-x64-release.msi" LAUNCHSPLUNK=0 AGREETOLICENSE=Yes INSTALLDIR="%ProgramFiles%\SplunkUniversalForwarder" SERVICESTARTTYPE=auto /quiet
copy deploymentclient.conf "%ProgramFiles%\SplunkUniversalForwarder\etc\system\default" NET START SplunkForwarder" /qn ADVANCED_OPTIONS=1 CHANNEL=100}

} 
