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
    Get-ADComputerOuNames.ps1

.DESCRIPTION
    For a list of computers of a given role, looks up each computer's organizational-unit name and exports the computer-to-OU mapping to CSV.

.FUNCTIONALITY
    Maps computers to their OU names.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$role = "core"
$computersListPath = "\\SERVER\SHARE\...\ADComputerObjects"
$computersList = "$computersListPath\$($role).txt"
$outfile = "$computersListPath\output.csv"
if(Test-Path $outfile){rm $outfile}
"Computer,OU_Name" | Out-File $outfile -Append ascii
$computers = Get-Content $computersList
$ouRoles = @()
$computers | ForEach-Object {
    $computer = $_
    $ouName = (((Get-ADComputer -Identity $computer).DistinguishedName).split("=")[2]).split(",")[0]
    "$computer,$ouName" 
    "$computer,$ouName" | Out-File $outfile -Append ascii
}