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
    WSUS_List_Server_Groups_v002.ps1

.DESCRIPTION
    Connects to the WSUS server and lists its computer target groups.

.FUNCTIONALITY
    Lists WSUS computer target groups.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#WSUS Server
$Server = "srv-wsus-app1"

[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
#Connect to WSUS server
$Wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($server, $false,8530)

#List all WSUS target groups
$wsus.GetComputerTargetGroups()

#Get WSUS group you want
#$mygroup = $wsus.GetComputerTargetGroups() | ? {$_.Name -eq "00_servers"}
$mygroup = $wsus.GetComputerTargetGroups() | ? {$_.Name -eq "01_servers"}
#$mygroup = $wsus.GetComputerTargetGroups() | ? {$_.Name -eq "02_servers"}

#List members of WSUS Group by FQDN and output file to path
#$mygroup.GetComputerTargets() | select FullDomainName | Out-File -FilePath C:\temp\ServerPilot.txt 
$mygroup.GetComputerTargets() | select FullDomainName | Out-File -FilePath C:\temp\ServerGroup1.txt 
#$mygroup.GetComputerTargets() | select FullDomainName | Out-File -FilePath C:\temp\ServerGroup2.txt