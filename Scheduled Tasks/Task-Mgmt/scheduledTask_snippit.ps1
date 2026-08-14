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
    scheduledTask_snippit.ps1

.DESCRIPTION
    Snippet that creates a one-time scheduled task to install the Splunk forwarder MSI on a target server.

.FUNCTIONALITY
    Creates a scheduled task to install software.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>




Write-Host "Before scheduled task creation";
            #Creates the new scheduled Task
			SCHTASKS /create /s $SVR /TN "Splunk Agent Install" /SC "Once" /RU "domain\sysadmin" /RP "<password>" /SD "08/15/2016" /ST "10:00" /TR "C:\SplunkInstaller\splunkforwarder-6.4.2-00f5bb3fa822-x64-release.msi msiexec.exe /i "splunkforwarder-6.4.2-00f5bb3fa822-x64-release.msi" LAUNCHSPLUNK=0 AGREETOLICENSE=Yes INSTALLDIR="%ProgramFiles%\SplunkUniversalForwarder" SERVICESTARTTYPE=auto /quiet
copy deploymentclient.conf "%ProgramFiles%\SplunkUniversalForwarder\etc\system\default"
NET START SplunkForwarder
 /REBOOT=10 /NOTIFY=1" /f

Write-Host "After scheduled task creation";

            $Check = schtasks /query /s $SVR /TN "Splunk_Agent_Install" /fo CSV | ConvertFrom-CSV
			If($Check -eq $Null){
				Add-Content -Path $LogFile -Value "$SVR,Online,Failed to Add"
				}
			Else{
				Add-Content -Path $LogFile -Value "$SVR,Online,$($Check.status)"
				}

# NOTE: this is a reference snippet (folder: ORG\reference\pending) extracted from a larger
# script — it originally continued with an Else branch for the offline case, wrapped in an
# outer If (Test-Connection ...) not included in this excerpt. Left as the flat sequence of
# statements above rather than inventing the exact wrapping condition/variable names.