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
    Get-ADComputerOuDn.ps1

.DESCRIPTION
    Resolves a list of organizational-unit names to their distinguished names and writes them to a file.

.FUNCTIONALITY
    Resolves OU names to distinguished names.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>


$computersListPath = "\\SERVER\SHARE\...\ADComputerObjects"
$outlist = "$computersListPath\corpOUs.txt"
$outfile = "$computersListPath\ous.txt"
if(Test-Path $outfile){rm $outfile}

$ouRoles = Get-Content $outlist
$ouRoles | ForEach-Object {
    $ouName = $_
    $ou = (Get-ADOrganizationalUnit -filter "Name -like '$ouName'").DistinguishedName
    $ou
    $ou | Out-File $outfile -Append ascii
}