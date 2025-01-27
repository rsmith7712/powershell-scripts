# LEGAL
<# LICENSE
    MIT License, Copyright 2023 Richard Smith

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
   - Find-Inactive-Computers-in-Active-Directory.ps1

.SYNOPSIS
   - Find Inactive Computers in Active Directory

.FUNCTIONALITY
   - Run the commands, adjust the value of the $DaysInactive variable
    to suit your needs. The script below will search for and collect
    all computers that have not logged in for the last 90 days, and
    export the list of stale computer accounts to a CSV file.

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Specify inactivity range value below
#$DaysInactive = 90
$DaysInactive = 180

# $time variable converts $DaysInactive to LastLogonTimeStamp property format for the -Filter switch to work
$time = (Get-Date).Adddays(-($DaysInactive))

# Identify and collect inactive computer accounts:
Get-ADComputer -Filter {LastLogonTimeStamp -lt $time} -ResultPageSize 2000 -resultSetSize $null -Properties Name, OperatingSystem, SamAccountName, DistinguishedName, LastLogonDate| Export-CSV “C:\Temp\Active-Directory-Computer-Objects-Inactive-180-Days.CSV” –NoTypeInformation