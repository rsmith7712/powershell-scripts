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
    AD-windowsClientRegistryAddTrustedSitesRemotely.ps1

.SYNOPSIS
    Script copies files to remote systems and adds Trusted Sites to Windows Registry

.FUNCTIONALITY
    Prompts for Input

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts - AD Windows Client Registry Add Trusted Sites Remotely
#>

# Elevating script permissions to bypass UAC roadblocks
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
	Echo "This script needs to be run As Admin"
	Break
}

# Enable PowerShell Remote Sessions
Enable-PSRemoting -Force;

# Set Execution Policy to Unrestricted
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Sets the Server Inclusion List from a Text File
$ServerList = Get-Content "\\FILE_SERVER\Shares\UTILITY\list_Remote_TrustedSites_ADD.txt"

ForEach ($Server in $ServerList)
{
	## Office.com Entries
	set-location "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
	set-location ZoneMap\Domains
	new-item office.com
	set-location office.com
	new-itemproperty . -Name * -Value 2 -Type DWORD
	
	## Microsoft.com Entries
	set-location "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
	set-location ZoneMap\Domains
	new-item microsoft.com
	set-location microsoft.com
	new-itemproperty . -Name * -Value 2 -Type DWORD
}