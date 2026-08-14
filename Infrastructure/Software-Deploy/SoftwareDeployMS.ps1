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
    SoftwareDeployMS.ps1

.DESCRIPTION
    Copies a chosen installer to a prompted remote computer and runs a silent installation (variant).

.FUNCTIONALITY
    Deploys and silently installs software to a remote computer.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$computers = Read-Host "Enter Computer Name"

get-childitem -Path C:\Software\Softwaredeployment | Format-List -property name

$software = Read-Host "Enter Software File Name"



$computers | where{Test-Connection $_ -quiet -count 1} | ForEach-Object{

Copy-Item C:\software\softwaredeployment\$software -recurse "\\$computers\C$\software"

Get-Service winrm -ComputerName $computers | Set-Service -ComputerName $computers -Status running

Invoke-Command -Credential domain\helpdsk -computername $computers -scriptblock{ cmd.exe /c \\$computers\C$\...\$software /quiet /passive /norestart }

}