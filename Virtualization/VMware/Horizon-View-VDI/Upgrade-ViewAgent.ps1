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
    Upgrade-ViewAgent.ps1

.DESCRIPTION
    Upgrades the VMware Horizon View Agent on computers in a list, detecting OS architecture and the installed agent version.

.FUNCTIONALITY
    Upgrades the VMware View Agent.

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
        $OSarch = (Get-WmiObject win32_operatingsystem -ComputerName $Computer).OSarchitecture
        $GUID = Get-WmiObject Win32_Product -Computer $Computer -Filter "name like '%view agent%'" | Select-Object IdentifyingNumber,Version
        If($GUID.IdentifyingNumber -eq $NULL)
        {
            Write-Host "Unable to locate an install of the Horizon View Agent on $Computer. Skipping." -ForegroundColor Red -BackgroundColor White
        }
        If($OSarch -eq "64-bit")
        {
            Write-Host "$Computer is accessible. $OSarch OS found. Current Agent is $($GUID.Version). Launching upgrader." -ForegroundColor Green
            If(!(Test-Path \\$Computer\c$\...\VMware-viewagent-x86_64-6.1.0-2509441.exe))
            {
                Copy-Item -Path "\\SERVER\SHARE\...\Horizon 6.0\VMware-viewagent-x86_64-6.1.0-2509441.exe" -Destination "\\$Computer\c$\Software"
            }
            Start-Process cmd.exe -ArgumentList "/c C:\Software\launchit64.bat $computer $($GUID.IdentifyingNumber)" 
        }
        ElseIf($OSarch -eq "32-bit")
        {
            Write-Host "$Computer is accessible. $OSarch OS found. Current Agent is $($GUID.Version). Launching upgrader." -ForegroundColor Green
            If(!(Test-Path \\$Computer\c$\...\VMware-viewagent-6.1.0-2509441.exe))
            {
                Copy-Item -Path "\\SERVER\SHARE\...\Horizon 6.0\VMware-viewagent-6.1.0-2509441.exe" -Destination "\\$Computer\c$\Software"
            }
            Start-Process cmd.exe -ArgumentList "/c C:\Software\launchit32.bat $computer $($GUID.IdentifyingNumber)"
        }
        Else
        {
            Write-Host "Unable to determine OS Architecture and/or GUID of $Computer. Skipping." -ForegroundColor Red -BackgroundColor White
        }
    }
    Else{
        Write-Host "Unable to access the c$ share of $Computer. Skipping." -ForegroundColor Red
    }
}