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
    Get-Users.ps1

.DESCRIPTION
    Scans recent log files on a file server and extracts lines mentioning users (excluding invalid/password lines) to a text file.

.FUNCTIONALITY
    Extracts user references from server logs.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$Files = get-childitem -Path "\\SERVER\SHARE\...\*" -Include *.log
$OutFile = "C:\Temp\Users.txt"

ForEach($File in $Files){
    If($File.LastWriteTime -gt (Get-Date).adddays(-90)){
        Get-Content "\\SERVER\SHARE\...\$($File.Name)" | Select-String -Pattern "User" |  Select-String -Pattern "Invalid" -NotMatch | Select-String -Pattern "Password" -NotMatch | Select-Object line | out-file $OutFile -append
    }
}