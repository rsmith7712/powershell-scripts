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
    Get-LocalAdmins.ps1

.SYNOPSIS
Gets the members of the local administrators of the computer 
and outputs the result to a CSV file.

.PARAMETER Computers
Specifies the Computer names of devices to query

.INPUTS
System.String. Get-LocalAdmins can accept a string value to
determine the Computers parameter.

.EXAMPLE
Get-LocalAdmins -Computers CL1,CL2

.EXAMPLE
Get-LocalAdmins -Computers (Get-Content -Path "$env:HOMEPATH\Desktop\computers.txt")

.EXAMPLE
Get-LocalAdmins -Computers DC,SVR8 | Format-Table -AutoSize -Wrap

.EXAMPLE
Get-LocalAdmins -Computers DC,SVR8 | Export-Csv -Path "$env:HOMEPATH\Desktop\LocalAdmin.csv" -NoTypeInformation

.LINK
Source script: https://gallery.technet.microsoft.com/223cd1cd-2804-408b-9677-5d62c2964883

.FUNCTIONALITY
    Gets the members of the local administrators of the computer
    and outputs the result to a CSV file.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Function Get-LocalAdmins {
    Param(
        [Parameter(Mandatory)]
        [string[]]$Computers
        )
    # testing the connection to each computer via ping before
    # executing the script
    foreach ($computer in $Computers) {
        if (Test-Connection -ComputerName $computer -Quiet -count 1) {
            $livePCs += $computer
        } else {
            Write-Verbose -Message ('{0} is unreachable' -f $computer) -Verbose
        }
    }

    $list = new-object -TypeName System.Collections.ArrayList
    foreach ($computer in $livePCs) {
        $admins = Get-WmiObject -Class win32_groupuser -ComputerName $computer | 
            Where-Object {$_.groupcomponent -like '*"Administrators"'} 
        $obj = New-Object -TypeName PSObject -Property @{
            ComputerName = $computer
            LocalAdmins = $null
        }
        foreach ($admin in $admins) {
            $null = $admin.partcomponent -match '.+Domain\=(.+)\,Name\=(.+)$' 
            $null = $matches[1].trim('"') + '\' + $matches[2].trim('"') + "`n"
            $obj.Localadmins += $matches[1].trim('"') + '\' + $matches[2].trim('"') + "`n"
        }
        $null = $list.add($obj)
    }
    $list
}