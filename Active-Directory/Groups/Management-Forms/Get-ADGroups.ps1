# LEGAL
<# LICENSE
    MIT License, Copyright 2018 Richard Smith

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
    Get-ADGroups.ps1

.SYNOPSIS
  Gets the membership for all groups in AD.
 
.DESCRIPTION
  Does Stuffâ„¢
 
.NOTES
  Version:        1.1
  Author:         Richard Smith / user26
  Creation Date:  01/24/2018
  Purpose/Change: Fixed some logic issues with how groups are written to the csv.

.HISTORY
  Version:        1.0
  Creation Date:  01/24/2018

.FUNCTIONALITY
    Does Stuffâ„¢

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#$ErrorActionPreference = "SilentlyContinue"

# ----------------------------------------------------------------------------------------------
# Logging
$script:log_full_filepath = "C:\AD_GroupMembership_Details.csv"
If(Test-Path $script:log_full_filepath){
    Remove-Item $script:log_full_filepath -Force
	}
New-Item $script:log_full_filepath -type file -force
function append_log($message){
	Add-Content $script:log_full_filepath "$message"
    }
# ----------------------------------------------------------------------------------------------
# Functions
Function Dump-Members($Group)
{
    $Current = $Group.Name
    $Users = ($Group.Members | Get-ADobject).name
    $Count = $Users.Count
    If($Count -eq 0){ # Writes the group to the csv, in the case of empty groups.
        Append_log "$Current,"
    }
    ForEach($User in $Users)
    {
        If($Count -eq 1){
            Append_log "$Current,$User"
        }
        ElseIf($User -eq $Users[0]){ # Writes the group name on the first user only, for readability.
            Append_log "$Current,$User"
        }
        else {
            Append_log ",$User"
        }
    }
}
# ----------------------------------------------------------------------------------------------
# Script
append_log "Group,User" #Header for CSV

$GroupMembership = Get-AdGroup -ResultSetSize 5000 -Filter * -Properties Name,Members

ForEach ($Group in $GroupMembership)
{
    Dump-Members $Group
}