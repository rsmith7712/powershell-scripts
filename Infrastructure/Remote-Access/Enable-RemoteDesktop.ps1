# LEGAL
<# LICENSE
    MIT License, Copyright 2021 Richard Smith

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
    Enable-RemoteDesktop.ps1

.DESCRIPTION
    Tests whether Remote Desktop (TCP 3389) is listening on a computer and enables Remote Desktop if needed.

.FUNCTIONALITY
    Enables Remote Desktop on a remote computer.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>


Function Test-TCP3389($computername)
{
    $test3389 = Test-NetConnection -Port 3389 -ComputerName $computername
    if ($test3389.tcptestsucceeded -eq $true)
    {
        Write-Host "Remote Desktop Services (TCP port 3389) is listening on $computername."-ForegroundColor Yellow
        Return 0
    }
}#---------[END Test-TCP3389]---------
Function Enable-RemoteDesktop($computername)
{
    Invoke-Command -Computername $computername -ScriptBlock {
        $rdpstatus = Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections"
        Clear-Host
        if($($rdpstatus.fDenyTSConnections) -ne "0")
        {
            Write-Host "Remote Desktop Services currently disabled on $env:computername.`enabling RDP services now..." -ForegroundColor Yellow
            Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" –Value 0
            Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
            Stop-Service "UmRdpService" -ErrorAction SilentlyContinue | Out-Null
            Stop-Service "TermService" -ErrorAction SilentlyContinue | Out-Null
            Start-Service "UmRdpService" -ErrorAction SilentlyContinue | Out-Null
            Start-Service "TermService" -ErrorAction SilentlyContinue | Out-Null
        }
            else
            {
                Write-Host "Remote Desktop Services is already enabled on $env:computername."-ForegroundColor Yellow
            }
    }
}#---------[END Enable-RemoteDesktop]---------

######## Script BEGIN ########
    $computername = Read-Host -Prompt "Enter Remote Hostname"
    Enable-RemoteDesktop -computername $computername
    Test-TCP3389 -computername $computername
######### Script END #########

