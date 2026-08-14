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
    Set-NLA.ps1

.DESCRIPTION
    Enables or disables Network Level Authentication (NLA) for RDP on a computer via WMI.

.FUNCTIONALITY
    Sets RDP Network Level Authentication.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

param($ComputerName = $env:COMPUTERNAME,$SetNLA = "Off")
Function Set-NLA($ComputerName,$setnla)
{
    switch ($setnla)
    {
        "On"  {$newnla = 1}
        "Off" {$newnla = 0}
    }
    $wmi = Get-WmiObject -class Win32_TSGeneralSetting -Namespace root\cimv2\terminalservices -ComputerName $ComputerName -Filter "TerminalName='RDP-tcp'"
    $wmi | gm
    #$nla = $wmi.UserAuthenticationRequired
    $nla = $wmi.SetUserAuthenticationRequired(0)
    return $nla
}
$ComputerName = "site"
$SetNLA = "Off"
Set-NLA -ComputerName $ComputerName -setnla $SetNLA