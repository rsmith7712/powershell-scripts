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
    Alt-ViewAgent.ps1

.DESCRIPTION
    Copies the VMware Horizon View Agent (64-bit) installer to computers in a list if not already present.

.FUNCTIONALITY
    Deploys the VMware View Agent (64-bit).

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$ComputerList = "C:\software\horizonlist.txt"

$Computers = Get-Content $ComputerList

ForEach($Computer in $Computers)
{
    If(Test-Path \\$Computer\c$)
    {
        Write-Host "$Computer is accessible. Pushing file now." -BackgroundColor Green
        If(!(Test-Path\\$Computer\c$\...\VMware-viewagent-x86_64-6.1.0-2509441.exe))
        {
            Copy-Item -Path "\\SERVER\SHARE\...\Horizon 6.0\VMware-viewagent-x86_64-6.1.0-2509441.exe" -Destination "\\$Computer\c$\Software"
        }
        Start-Process cmd.exe -ArgumentList "/c C:\Software\launchit.bat $computer"
    }
    Else{
        Write-Host "Unable to access the c$ share of $Computer. Skipping." -BackgroundColor Red
    }
}