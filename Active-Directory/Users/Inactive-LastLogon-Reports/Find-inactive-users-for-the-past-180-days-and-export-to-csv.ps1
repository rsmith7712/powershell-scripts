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
    Find-inactive-users-for-the-past-180-days-and-export-to-csv.ps1

.DESCRIPTION
    Finds inactive users in Active Directory for the past 180 days and exports them to a CSV file.

.FUNCTIONALITY
    This script is designed to be used as part of an audit of Active Directory
    User Accounts that have been inactive for longer than 180-days.  The
    script will query Active Directory for user accounts that have not had
    their last logon time within the last 180-days and export the results to a CSV file.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>

# set the date (the number of days)
$NumberOfDays = 180

# set the timeframe ranging for the amount of days entered
$TimeRange = (Get-Date).Adddays(-($NumberOfDay))

# checks for inactive users within 180 days timeframe
Get-ADUser -Filter {LastLogonTimeStamp -lt $TimeRange } -Properties * | Select Name, LastLogonDate, PasswordLastSet | Export-Csv C:\Temp\Inactive-ADUser-Accounts-180-Days.csv -NoTypeInformation