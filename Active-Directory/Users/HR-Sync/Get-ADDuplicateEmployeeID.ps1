# LEGAL
<# LICENSE
    MIT License, Copyright 2019 Richard Smith

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
    Get-ADDuplicateEmployeeID.ps1

.SYNOPSIS
  Get-ADDuplicateEmployeeID.ps1
 .DESCRIPTION
  Returns user accounts that share duplicate EmployeeID attributes in Active Directory
.EXAMPLE
  Get-ADDuplicateEmployeeID -output 'c:\temp\outfile.csv'
.NOTES
  Version:        1.0
  Author:         user10
  Creation Date:  06/01/2019
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0 (06/01/2019)
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Returns user accounts that share duplicate EmployeeID attributes in Active Directory

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$Script:ProductName = "Get-ADDuplicateEmployeeID"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName).csv"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
$ErrorActionPreference = "SilentlyContinue"

############# Functions #############
Function Get-ADDuplicateEmployeeID($output)
{
    Clear-Host
    Write-Host "Searching Active Directory for user accounts that share duplicate EmployeeID attribute values.  Please wait..." -ForegroundColor Yellow
    $ADUser = Get-ADUser -Filter 'EmployeeID -like "*"' -Properties EmployeeID
    $EmployeeDuplicates = @()
    $ADUser | ForEach-Object{
        $employeeid = $_.employeeid
        if(((get-aduser -filter 'Employeeid -like $employeeid').count) -ge 2 -and $employeeid -ne "Contractor" -and $employeeid -ne "Term" -and $employeeid -ne "Australia")
        {
            $EmployeeDuplicates += $employeeid
        }
    }
    $EmployeeDuplicates|ForEach-Object{
        get-aduser -Filter 'EmployeeID -like $_' -Properties EmployeeID |
        Select-Object -Property Name, SamAccountName, EmployeeID
    } | 
    Export-Csv -Path $output -NoTypeInformation
}#------------[END Function]------------

############# Script Starts #############

Get-ADDuplicateEmployeeID -output $Script:Logfile
Invoke-Item $Script:Logfile

############# Script Starts #############
