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
    evilNotEvil-OperatingSystems.ps1

.DESCRIPTION
    Scans Active Directory computers and separates legacy operating systems (Windows 7, Windows XP) into per-OS CSV exports with counts.

.FUNCTIONALITY
    Reports and counts legacy Windows OS computers in AD.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

import-module ActiveDirectory
$computers = get-adcomputer -Filter * -properties "OperatingSystem" -SearchBase "DC=domain,DC=com"
$i = 0
$j = 0
Foreach ($computer in $computers) {
    if ($computer.operatingSystem -like "Windows 7*") {
        $i++
        '"{0}","{1}","{2}"' -f $computer.Name, $computer.OperatingSystem, "$($computer.DistinguishedName)" | Out-file -append C:\test7.csv
        }
    elseif ($computer.OperatingSystem -like "Windows XP*") {
        $j++
        '"{0}","{1}","{2}"' -f $computer.Name, $computer.OperatingSystem, "$($computer.DistinguishedName)" | Out-file -append C:\testXP.csv
        }
    else {
        $_
        }
}
write-host "$i Win 7"
write-host "$j Win xp"
$k = $i+$j
write-host "$k Total"