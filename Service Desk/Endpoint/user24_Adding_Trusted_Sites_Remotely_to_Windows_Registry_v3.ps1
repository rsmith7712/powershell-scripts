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
    user24_Adding_Trusted_Sites_Remotely_to_Windows_Registry_v3.ps1.txt

.DESCRIPTION
    		Script copies files to ALL DOMAIN SYSTEMS and adds Trusted Sites to Windows Registry

.FUNCTIONALITY
    		Script copies files to ALL DOMAIN SYSTEMS and adds Trusted Sites to Windows Registry

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
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


FUNCTION microsoft
{
	set-location "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
	set-location ZoneMap\Domains
	new-item microsoft.com
	set-location microsoft.com
	new-itemproperty . -Name -Value 2 -Type DWORD
}

FUNCTION yammer
{
	set-location "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
	set-location ZoneMap\Domains
	new-item www.yammer.com
	set-location www.yammer.com
	new-itemproperty . -Name -Value 2 -Type DWORD
}

FUNCTION office
{
	set-location "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
	set-location ZoneMap\Domains
	new-item office.com
	set-location office.com
	new-itemproperty . -Name -Value 2 -Type DWORD
}

FUNCTION sharepoint
{
	set-location "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
	set-location ZoneMap\Domains
	new-item sharepoint.com
	set-location sharepoint.com
	new-itemproperty . -Name -Value 2 -Type DWORD
}

FUNCTION domain
{
	set-location "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
	set-location ZoneMap\Domains
	new-item domain.sharepoint.com
	set-location domain.sharepoint.com
	new-itemproperty . -Name -Value 2 -Type DWORD
}

FUNCTION domain-my
{
	set-location "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
	set-location ZoneMap\Domains
	new-item domain-my.sharepoint.com
	set-location domain-my.sharepoint.com
	new-itemproperty . -Name -Value 2 -Type DWORD
}

FUNCTION domain-files
{
	set-location "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
	set-location ZoneMap\Domains
	new-item domain-files.sharepoint.com
	set-location domain-files.sharepoint.com
	new-itemproperty . -Name -Value 2 -Type DWORD
}

FUNCTION tasks
{
	set-location "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
	set-location ZoneMap\Domains
	new-item tasks.office.com
	set-location tasks.office.com
	new-itemproperty . -Name -Value 2 -Type DWORD
}

FUNCTION powerbi
{
	set-location "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
	set-location ZoneMap\Domains
	new-item powerbi.microsoft.com
	set-location powerbi.microsoft.com
	new-itemproperty . -Name -Value 2 -Type DWORD
}

FUNCTION sway
{
	set-location "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
	set-location ZoneMap\Domains
	new-item sway.com
	set-location sway.com
	new-itemproperty . -Name -Value 2 -Type DWORD
}

# Sets the Inclusion OU
#$OUs = @("Corporate Desktops, OU=Corporate Computers", "Corporate Laptops, OU=Corporate Computers", "Corporate View Desktops, OU=Corporate Computers", "Disabled Computers, OU=Corporate Computers", "IS, OU=Corporate Computers", "Patch Exclusion, OU=Corporate Computers", "Service Desk, OU=Corporate Computers")

#$OUs = @("Computers")
 
#$OUs = @("Corporate Desktops, OU=Corporate Computers")

#$OUs = @("Corporate Laptops, OU=Corporate Computers")

#$OUs = @("Corporate View Desktops, OU=Corporate Computers")

#$OUs = @("Disabled Computers, OU=Corporate Computers")

#$OUs = @("IS, OU=Corporate Computers")

$OUs = @("Patch Exclusion, OU=Corporate Computers")

#$OUs = @("Service Desk, OU=Corporate Computers")


$SearchBase = "OU=" + $OU + ", DC=Domain, DC=com"

#$GetServer = Get-ADComputer -LDAPFilter "(name=*)" -SearchBase $SearchBase

#$GetServer = Get-ADComputer -Filter * -SearchBase $SearchBase -Properties name, operatingSystemVersion, operatingSystem

$GetServer = Get-ADComputer -Filter * -SearchBase $SearchBase

$Servers = $GetServer.name

ForEach ($Server in $Servers)
{
	microsoft
	yammer
	office
	sharepoint
	domain
	domain-my
	domain-files
	tasks
	powerbi
	sway
}