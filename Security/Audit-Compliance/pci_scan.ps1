# LEGAL
<# LICENSE
    MIT License, Copyright 2022 Richard Smith

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
    pci_scan.ps1.txt

.DESCRIPTION
    Auditor-provided PCI compliance check commands (WMIC replaced with PowerShell where available), such as PowerShell version checks.

.FUNCTIONALITY
    Runs PCI auditor scan commands.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#

The following are commands received from the auditor.

Commented out WMIC have been replaced with updated
PowerShell where available.


Use to check Ps version if directly on system.
Most production 2008r2 servers only have v2:

$PSVersionTable

#>

#REM list all installed Windows updates
#wmic qfe get
Get-HotFix | Export-Csv C:\PCI_SRV_DC_HotFix.csv

#REM list all registered services
#wmic service get
Get-Service | Export-Csv C:\PCI_SRV_DC_Service.csv

#REM list all running processes
#wmic process get
Get-Process | Export-Csv C:\PCI_SRV_DC_Process.csv

#REM list all toc/udp sockets in use w/PIDs
netstat -ano | Export-Csv C:\PCI_SRV_DC_NetStat.csv

#REM list local admins
net localgroup administrators | Export-Csv C:\PCI_SRV_DC_AdminGroup.csv

#REM list folks who can RDP to this box
net localgroup "remote desktop users" | Export-Csv C:\PCI_SRV_DC_RemoteDesktopUsers.csv

#REM get GPO results for the machine…this is an issue if there is to RSoP for the user, even if we do not care about the user
gpresult /v /scope COMPUTER | Export-Csv C:\PCI_SRV_DC_GPResult.csv

#REM see what protocols and ciphers SChannel supports
reg query hklm\system\currentcontrolset\control\securityproviders\schannel /s | Export-Csv C:\PCI_SRV_DC_SChannel.csv

#REM see if the page file is wiped at shutdown
reg query "hklm\system\currentcontrolset\control\session manager\memory management" /v ClearPageFileAtShutdown | Export-Csv C:\PCI_SRV_DC_MemMgmt.csv

#REM see if the page file is encrypted
fsutil behavior query encryptpagingfile | Export-Csv C:\PCI_SRV_DC_FsUtil.csv