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
    create_srv-ads-sch01_schtask.ps1

.DESCRIPTION
    Creates the scheduled tasks (production and test) that run the SharePoint report-migration and retail-report sync scripts under a service account.

.FUNCTIONALITY
    Creates report-migration and sync scheduled tasks.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>


##### [PRODUCTION] #####
SCHTASKS.exe /create /s "srv-ads-sch01" /TN "Migrate-SRV_DropBox_Reports" /SC "Daily" /RU "DOMAIN\DOMAINScheduler" /RP "<password>" /ST "1:00" /TR "powershell.exe -executionpolicy bypass -file C:\temp\Migrate-SPOSscReportsDropBox.ps1" /f

SCHTASKS.exe /create /s "srv-ads-sch01" /TN "Migrate-SPOSscReportsSPReports" /SC "Daily" /RU "DOMAIN\DOMAINScheduler" /RP "<password>" /ST "1:00" /TR "powershell.exe -executionpolicy bypass -file C:\temp\Migrate-SPOSscReportsSPReports.ps1" /f

######## [TEST] ########
SCHTASKS.exe /create /s "ts0-aut-app1" /TN "Migrate-SRV_DropBox_Reports" /SC "Daily" /RU "DOMAIN\DOMAINScheduler" /RP "<password>" /ST "1:00" /TR "powershell.exe -executionpolicy bypass -file C:\temp\Migrate-SPOSscReportsDropBox.ps1" /f

SCHTASKS.exe /create /s "ts0-aut-app1" /TN "Migrate-SPOSscReportsSPReports" /SC "Daily" /RU "DOMAIN\DOMAINScheduler" /RP "<password>" /ST "1:00" /TR "powershell.exe -executionpolicy bypass -file C:\temp\Migrate-SPOSscReportsSPReports.ps1" /f
Sync-SPORetailReports
SCHTASKS.exe /create /TN "Sync-SPORetailReports" /SC "Daily" /RU "DOMAIN\DOMAINScheduler" /RP "<password>" /ST "11:00" /TR "powershell.exe -executionpolicy bypass -file C:\temp\Sync-SPORetailReports.ps1" /f