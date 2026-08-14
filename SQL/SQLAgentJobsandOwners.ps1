# LEGAL
<# LICENSE
    MIT License, Copyright 2015 Richard Smith

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
    SQLAgentJobsandOwners.ps1

.DESCRIPTION
    Lists the SQL Server Agent jobs on a server with their owner, status and last run outcome (via SMO).

.FUNCTIONALITY
    Reports SQL Agent jobs and owners.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Script to Display information about the Jobs installed on the Server
# Lists Owner and Status, reporting it in a Table Format

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO")
$sqlServerName = 'localhost\developer'

$sqlServer = New-Object Microsoft.SqlServer.Management.Smo.Server($sqlServerName)

foreach($job in $sqlServer.JobServer.Jobs)
{
    $job | select Name, OwnerLoginName, IsEnabled, LastRunDate, LastRunOutcome | format-table
}

# Script to Display information about the Jobs installed on the Server
# Lists Owner, Status, Creation Date and the Date Last Modified

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO")
$sqlServerName = 'localhost\developer'

$sqlServer = New-Object Microsoft.SqlServer.Management.Smo.Server($sqlServerName)

foreach($job in $sqlServer.JobServer.Jobs)
{
    $job | select Name, OwnerLoginName, IsEnabled, LastRunDate, LastRunOutcome, DateCReated, DateLastModified
}
