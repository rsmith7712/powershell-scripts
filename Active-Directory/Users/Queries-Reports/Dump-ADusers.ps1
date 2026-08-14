# LEGAL
<# LICENSE
    MIT License, Copyright 2018 Richard Smith

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
    Dump-ADusers.ps1

.DESCRIPTION
    Exports all Active Directory users that have an EmployeeID (full name, SAM account name, employee ID) to a CSV.

.FUNCTIONALITY
    Exports AD users with employee IDs to CSV.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>


$Users = Get-ADuser -Filter * -Properties EmployeeID | Where {$_.EmployeeID -ne $Null}
$Export = @()
ForEach($User in $Users){
    $userObject = new-object PSObject
    $userObject | add-member -MemberType NoteProperty -Name "FullName" -Value $User.Name
    $userObject | add-member -MemberType NoteProperty -Name "SamAccountName" -Value $User.SamAccountName
    $userObject | add-member -MemberType NoteProperty -Name "EmployeeID" -Value $User.EmployeeID
    $Export += $userObject
}

$Export | Export-CSV -Path C:\users\$ENV:Username\Desktop\PostSyncDump.csv -NoTypeInformation