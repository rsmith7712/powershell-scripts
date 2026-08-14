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
    find_NonSupportedOperatingSystems.ps1

.DESCRIPTION
    Queries Active Directory for computers running unsupported Microsoft operating systems (XP, Vista, NT4, 2000, 2003) and exports desktop and server results to CSV.

.FUNCTIONALITY
    Reports unsupported-OS computers in AD.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Run the below powershell command from Active Directory Powershell to get the list of all machines with Windows Vista and earlier versions.

# Query AD for Text dump of all server and desktop systems running unsupported Microsoft operating systems, as specified in query
#Get-ADcomputer -Filter {(operatingsystem -like "*xp*") -or (operatingsystem -like "*vista*") -or (operatingsystem -like "*4.0*")-or (operatingsystem -like "*2000*") -or (operatingsystem -like "*2003*")} -Property Name,OperatingSystem,OperatingSystemServicePack,lastlogontimestamp | Format-Table Name,OperatingSystem,OperatingSystemServicePack,@{name="lastlogontimestamp"; expression={[datetime]::fromfiletime($_.lastlogontimestamp)}} -Wrap -AutoSize > C:\temp\nonSupportedOperatingSystems.txt


# Query AD to get export results in CSV of Desktop systems running unsupported Microsoft operating systems, as specified in query
Get-ADcomputer -Filter {(operatingsystem -like "*xp*") -or (operatingsystem -like "*vista*")} -Property Name,OperatingSystem,OperatingSystemServicePack,lastlogontimestamp | Select-Object Name,OperatingSystem,OperatingSystemServicePack,@{name="lastlogontimestamp"; expression={[datetime]::fromfiletime($_.lastlogontimestamp)}} | Export-Csv C:\temp\report-nonSupportedOperatingSystems_Desktops.csv


# Query AD to get export results in CSV of Server systems running unsupported Microsoft operating systems, as specified in query
Get-ADcomputer -Filter {(operatingsystem -like "*4.0*")-or (operatingsystem -like "*2000*") -or (operatingsystem -like "*2003*")} -Property Name,OperatingSystem,OperatingSystemServicePack,lastlogontimestamp | Select-Object Name,OperatingSystem,OperatingSystemServicePack,@{name="lastlogontimestamp"; expression={[datetime]::fromfiletime($_.lastlogontimestamp)}} | Export-Csv C:\temp\report-nonSupportedOperatingSystems_Servers.csv