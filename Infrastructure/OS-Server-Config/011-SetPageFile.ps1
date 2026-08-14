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
    011-SetPageFile_3.ps1

    .SYNOPSIS
        Sets Page File to custom size
 
    .DESCRIPTION
        Disables automatic management of the pagefile, then applies the given values for path and page file size.
        Defaults to C:\pagefile.sys with a 4 gig pagefile.

## Disables automatically managed page file setting first
    $computer = Get-WmiObject Win32_computersystem -EnableAllPrivileges
    $computer.AutomaticManagedPagefile = $false
    $computer.Put()
 
## Select default pagefile
    $CurrentPageFile = Get-WmiObject -Query "select * from Win32_PageFileSetting where name='c:\\pagefile.sys'"

## Delete default pagefile
    $CurrentPageFile.delete()

## Create new pagefile on different partition
    Set-WMIInstance -Class Win32_PageFileSetting -Arguments @{name="d:\pagefile.sys";InitialSize = 4096; MaximumSize = 6144}

## Check pagefile settings
    #Gwmi win32_Pagefilesetting | Select Name, InitialSize, MaximumSize

.FUNCTIONALITY
    Disables automatic management of the pagefile, then applies the given values for path and page file size.
            Defaults to C:\pagefile.sys with a 4 gig pagefile.

    ## Disables automatically managed page file setting first
        $computer = Get-WmiObject Win32_computersystem -EnableAllPrivileges
        $computer.AutomaticManagedPagefile = $false
        $computer.Put()

    ## Select default pagefile
        $CurrentPageFile = Get-WmiObject -Query "select * from Win32_PageFileSetting where name='c:\\pagefile.sys'"

    ## Delete default pagefile
        $CurrentPageFile.delete()

    ## Create new pagefile on different partition
        Set-WMIInstance -Class Win32_PageFileSetting -Arguments @{name="d:\pagefile.sys";InitialSize = 4096; MaximumSize = 6144}

    ## Check pagefile settings
        #Gwmi win32_Pagefilesetting | Select Name, InitialSize, MaximumSize

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$computer = Get-WmiObject Win32_computersystem -EnableAllPrivileges
$computer.AutomaticManagedPagefile = $false
$computer.Put()
$CurrentPageFile = Get-WmiObject -Query "select * from Win32_PageFileSetting where name='c:\\pagefile.sys'"
$CurrentPageFile.delete()
Set-WMIInstance -Class Win32_PageFileSetting -Arguments @{name="d:\pagefile.sys";InitialSize = 4096; MaximumSize = 6144}

## Values for InitialSize and MaximumSize set to zero denote System Managed
#Set-WMIInstance -Class Win32_PageFileSetting -Arguments @{name="d:\pagefile.sys";InitialSize = 0;MaximumSize = 0}
