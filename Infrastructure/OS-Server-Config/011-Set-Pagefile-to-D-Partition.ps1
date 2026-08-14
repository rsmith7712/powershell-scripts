# LEGAL
<# LICENSE
    MIT License, Copyright 2023 Richard Smith

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
    011-Set-Pagefile-to-D-Partition_2_3.ps1

.DESCRIPTION
    Disables automatic pagefile management and relocates the pagefile from C: to the D: partition (variant).

.FUNCTIONALITY
    Moves the pagefile to the D: partition.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>


## PowerShell ##
#Run as administrator

#UNCHECK AUTOMATICALLY MANAGE PAGEFILE SIZE FOR ALL DRIVES
$pagefile = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges
$pagefile.AutomaticManagedPagefile = $false
$pagefile.put() | Out-Null

#SELECT PAGEFILE ON C:
$CurrentPageFile = Get-WmiObject -Query "select * from Win32_PageFileSetting where name='c:\\pagefile.sys'"

#DELETE PAGEFILE ON C:
$CurrentPageFile.delete()

#CREATE PAGEFILE ON D:
Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{name="D:\pagefile.sys";InitialSize = 4096; MaximumSize = 6144} -EnableAllPrivileges | Out-Null

<#
#########################

## BY CMD/BAT ##
#Disable AutomaticManagedPagefile
#wmic COMPUTERSYSTEM where name="%computername%" set AutomaticManagedPagefile=false

#Create Pagefile in new location
#wmic PAGEFILESET create name="D:\pagefile.sys"

#Amend InitialSize and MaximumSize figures, if required
#wmic PAGEFILESET where name="D:\\pagefile.sys" set InitialSize=4096,MaximumSize=6144

#Remove current Pagefile
#wmic PAGEFILESET where name="C:\\pagefile.sys" delete

#Set-ItemProperty -Path "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "ExistingPageFiles" -Value "\??\D:\pagefile.sys"

#Set-ItemProperty -Path "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "PagingFiles" -Value "D:\pagefile.sys" 0 0

#Reboot server to apply settings
#shutdown -r -t 0

#To verify Pagefile settings, run:
#Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"

#Run to confirm location of system Pagefile
#wmic PAGEFILE list /format:list

#>