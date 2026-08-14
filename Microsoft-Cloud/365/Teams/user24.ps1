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
    user24.ps1

.DESCRIPTION
    Script copies files to remote systems and adds Trusted Sites to Windows Registry
    #

.FUNCTIONALITY
    Script copies files to remote systems and adds Trusted Sites to Windows Registry
    #

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Elevating script permissions to bypass UAC roadblocks
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
	Echo This script needs to be run As Admin
	Break
}

# Enable PowerShell Remote Sessions
Enable-PSRemoting -Force;

# Set Execution Policy to Unrestricted
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Sets the Inclusion OU
$SearchBase = "DC=Domain, DC=com"

$GetServer = Get-ADComputer -LDAPFilter (name=) -SearchBase $SearchBase
$Servers = $GetServer.name

function sharepoint{
	set-location HKCUSoftwareMicrosoftWindowsCurrentVersionInternet Settings
	set-location ZoneMapDomains
	new-item sharepoint.com
	set-location sharepoint.com
	new-itemproperty . -Name  -Value 2 -Type DWORD
	}
function sharepoint.comdomain{
	set-location HKCUSoftwareMicrosoftWindowsCurrentVersionInternet Settings
	set-location ZoneMapDomains
	new-item sharepoint.comdomain
	set-location sharepoint.comdomain
	new-itemproperty . -Name  -Value 2 -Type DWORD
	}
function sharepoint.comdomain-my{
	set-location HKCUSoftwareMicrosoftWindowsCurrentVersionInternet Settings
	set-location ZoneMapDomains
	new-item sharepoint.comdomain-my
	set-location sharepoint.comdomain-my
	new-itemproperty . -Name  -Value 2 -Type DWORD
	}
function sharepoint.comdomaininv-files{
	set-location HKCUSoftwareMicrosoftWindowsCurrentVersionInternet Settings
	set-location ZoneMapDomains
	new-item sharepoint.comdomaininv-files
	set-location sharepoint.comdomaininv-files
	new-itemproperty . -Name  -Value 2 -Type DWORD
	}
function office.com{
	## Office.com Entries
	set-location HKCUSoftwareMicrosoftWindowsCurrentVersionInternet Settings
	set-location ZoneMapDomains
	new-item office.com
	set-location office.com
	new-itemproperty . -Name  -Value 2 -Type DWORD
	}
function microsoft.com{
	## Microsoft.com Entries
	set-location HKCUSoftwareMicrosoftWindowsCurrentVersionInternet Settings
	set-location ZoneMapDomains
	new-item microsoft.com
	set-location microsoft.com
	new-itemproperty . -Name  -Value 2 -Type DWORD
	}
function microsoft.compowerbi{
	set-location HKCUSoftwareMicrosoftWindowsCurrentVersionInternet Settings
	set-location ZoneMapDomains
	new-item microsoft.compowerbi
	set-location microsoft.compowerbi
	new-itemproperty . -Name  -Value 2 -Type DWORD
	}
function microsoft.comyammer.com{
	set-location HKCUSoftwareMicrosoftWindowsCurrentVersionInternet Settings
	set-location ZoneMapDomains
	new-item microsoft.comyammer.com
	set-location microsoft.comyammer.com
	new-itemproperty . -Name  -Value 2 -Type DWORD
	}
function microsoft.comoffice.com{
	set-location HKCUSoftwareMicrosoftWindowsCurrentVersionInternet Settings
	set-location ZoneMapDomains
	new-item microsoft.comoffice.com
	set-location microsoft.comoffice.com
	new-itemproperty . -Name  -Value 2 -Type DWORD
	}
function microsoft.comsway.com{
	set-location HKCUSoftwareMicrosoftWindowsCurrentVersionInternet Settings
	set-location ZoneMapDomains
	new-item microsoft.comsway.com
	set-location microsoft.comsway.com
	new-itemproperty . -Name  -Value 2 -Type DWORD
}

ForEach ($Server in $Servers)
    {
    sharepoint
    sharepoint.comdomain-my
    sharepoint.comdomaininv-files
    sharepoint.comdomain
    office.com
    microsoft.com
    microsoft.compowerbi
    microsoft.comyammer.com
    microsoft.comoffice.com
    microsoft.comsway.com
    }