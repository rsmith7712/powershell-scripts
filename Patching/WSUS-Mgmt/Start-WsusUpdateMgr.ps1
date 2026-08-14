# LEGAL
<# LICENSE
    MIT License, Copyright 2022 Richard Smith

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
    Start-WsusUpdateMgr.ps1

.DESCRIPTION
    Launches the WSUS Update Manager, re-elevating to administrator and verifying an STA WPF-capable PowerShell host.

.FUNCTIONALITY
    Launches the WSUS update-manager tool.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$VerbosePreference = "Continue"

#Validate user is an Administrator
Write-Verbose "Checking Administrator credentials"
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You are not running this as an Administrator!`nRe-running script and will prompt for administrator credentials."
    Start-Process -Verb "Runas" -File PowerShell.exe -Argument "-STA -noprofile -file $($myinvocation.mycommand.definition)"
	break
}

#Determine if this instance of PowerShell can run WPF 
Write-Verbose "Checking for STA"
If ($Host.Runspace.ApartmentState -ne "STA") {
    Write-Warning "This script must be run in PowerShell started using -STA switch.`nScript will attempt to open PowerShell in STA and run re-run script."
    Start-Process -File PowerShell.exe -Argument "-STA -noprofile -WindowStyle hidden -file $($myinvocation.mycommand.definition)"
    break
}

# Import the Functions
Set-Location $(Split-Path $MyInvocation.MyCommand.Path)
. ".\Functions\Wsus-UpdateManager.ps1"
. ".\UI\Wsus-UpdateManager.UI.ps1"

# Display the GUI
Show-WsusUpdateManagerUi | Out-Null