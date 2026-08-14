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
    Clean-Reports.ps1

.DESCRIPTION
    Removes report spreadsheets from the local store's Reports folders that do not belong to this UFO_NUMBER.

.FUNCTIONALITY
    Cleans mismatched store report files.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$storenum = $ENV:Computername.substring(0,4)

$Files = Get-ChildItem "C:\Reports\2015" -Include *.xl* -Recurse
$Files += Get-ChildItem "C:\Reports\2016" -Include *.xl* -Recurse
$Files += Get-ChildItem "C:\Reports\2017" -Include *.xl* -Recurse

foreach($File in $Files)
{
    $FileStore = $File.name.substring(0,4)
    If($FileStore -ne "$storenum")
    {
        $Test = [RegEx]::IsMatch($File.Name, "\d{4}")
        If($Test -eq $true)
        {
            Remove-Item -Path $File.FullName -Force
        }
    }
}