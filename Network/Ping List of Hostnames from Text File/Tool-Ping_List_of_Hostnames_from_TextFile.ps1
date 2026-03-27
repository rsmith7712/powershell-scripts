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
    Tool-Ping_List_of_Hostnames_from_TextFile.ps1

.DESCRIPTION
    This script is designed to copy files to remote systems and add Trusted
    Sites to the Windows Registry. It prompts the user for input, such as the list
    of hostnames and the files to be copied, and then performs the necessary
    operations on each remote system.

.FUNCTIONALITY
    - Prompts the user for a list of hostnames and files to be copied.
    - Copies specified files to remote systems.
    - Adds Trusted Sites to the Windows Registry on remote systems.

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>

$names = Get-content "C:\serverlist.txt"

foreach ($name in $names){
  if (Test-Connection -ComputerName $name -Count 1 -ErrorAction SilentlyContinue){
    Write-Host "$name,up" -ForegroundColor Green
  }
  else{
    Write-Host "$name,down" -ForegroundColor Red
  }
}