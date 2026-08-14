# LEGAL
<# LICENSE
    MIT License, Copyright 2025 Richard Smith

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
    HideGALContacts.ps1

.DESCRIPTION
    Elevates as administrator, prompts for a domain, domain controller and OU, then hides each external contact in the selected OU from the global address list.

.FUNCTIONALITY
    Hides external contacts in an OU from the GAL.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# HideGALContacts.ps1
# This script must run as Administrator.
# It prompts for a domain, an optional Domain Controller,
# scans for OUs immediately under the domain root,
# lets the user select one, then sets msExchHideFromAddressLists to True
# for each external contact in the selected OU.

# Function to check for administrative privileges and relaunch the script if not elevated.
function Ensure-RunningAsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "This script is not running as Administrator. Attempting to restart it with elevated privileges..."
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        Start-Process powershell -Verb RunAs -ArgumentList $arguments
        exit
    }
}

# Ensure the script is running as administrator.
Ensure-RunningAsAdmin

# Prompt for the domain name.
$domain = Read-Host "Enter the domain (e.g., Test.Hosterboys.com)"

# Convert the domain to a distinguished name.
# For example, Test.Hosterboys.com becomes DC=Test,DC=Hosterboys,DC=com.
$domainParts = $domain -split "\."
if ($domainParts.Count -eq 0) {
    Write-Error "The domain input appears to be invalid."
    exit
}
$domainDN = ($domainParts | ForEach-Object { "DC=$_" }) -join ","

Write-Host "`nDomain converted to DN: $domainDN"

# Prompt for an optional Domain Controller.
$domainController = Read-Host "Enter the Domain Controller (optional, e.g., dc01.test.hosterboys.com) - leave blank for default"

if ($domainController -eq "") {
    Write-Host "Using default Domain Controller."
} else {
    Write-Host "Using Domain Controller: $domainController"
}

Write-Host "`nScanning domain '$domain' (DN: $domainDN) for organizational units (OUs)...`n"

# Import the Active Directory module.
Import-Module ActiveDirectory -ErrorAction Stop

# Retrieve OUs immediately under the domain root.
try {
    if ($domainController -eq "") {
        $OUs = Get-ADOrganizationalUnit -Filter * -SearchBase $domainDN -SearchScope OneLevel -ErrorAction Stop
    } else {
        $OUs = Get-ADOrganizationalUnit -Filter * -SearchBase $domainDN -SearchScope OneLevel -Server $domainController -ErrorAction Stop
    }
}
catch {
    Write-Error "Error retrieving OUs for domain '$domain'. Please ensure the domain is correct, the Domain Controller is reachable, and you have proper permissions."
    Write-Error "Detailed Error: $_"
    exit
}

if (-not $OUs -or $OUs.Count -eq 0) {
    Write-Host "No organizational units were found immediately under the domain '$domain'."
    exit
}

# Display a numbered list of OUs.
Write-Host "Found the following OUs under the domain '$domain':"
for ($i = 0; $i -lt $OUs.Count; $i++) {
    Write-Host "[$($i + 1)] $($OUs[$i].Name)"
}

# Prompt the user to select the OU.
[int]$selection = 0
do {
    $selectionInput = Read-Host "Enter the number corresponding to the OU you want to run against"
    if ([int]::TryParse($selectionInput, [ref]$selection)) {
        if ($selection -ge 1 -and $selection -le $OUs.Count) {
            break
        }
    }
    Write-Host "Invalid selection. Please enter a number between 1 and $($OUs.Count)."
} while ($true)

# Get the selected OU's distinguished name.
$selectedOU = $OUs[$selection - 1]
$selectedOUDN = $selectedOU.DistinguishedName
Write-Host "`nYou selected: $($selectedOU.Name) (DN: $selectedOUDN)`n"

# Retrieve all contacts (objectClass = contact) in the selected OU.
try {
    if ($domainController -eq "") {
        $contacts = Get-ADObject -Filter 'objectClass -eq "contact"' -SearchBase $selectedOUDN -Properties msExchHideFromAddressLists -ErrorAction Stop
    } else {
        $contacts = Get-ADObject -Filter 'objectClass -eq "contact"' -SearchBase $selectedOUDN -Server $domainController -Properties msExchHideFromAddressLists -ErrorAction Stop
    }
}
catch {
    Write-Error "Error retrieving contacts from OU '$selectedOUDN'. Please check your permissions and the OU DN."
    Write-Error "Detailed Error: $_"
    exit
}

if (-not $contacts -or $contacts.Count -eq 0) {
    Write-Host "No contacts found in the selected OU."
    exit
}

# Loop through each contact and set msExchHideFromAddressLists to True.
foreach ($contact in $contacts) {
    Write-Host "Updating contact: $($contact.Name)"
    try {
        Set-ADObject -Identity $contact.DistinguishedName -Replace @{msExchHideFromAddressLists=$true}
        Write-Host "Successfully updated $($contact.Name)."
    }
    catch {
        Write-Error "Failed to update $($contact.Name): $_"
    }
}

Write-Host "`nUpdate complete. All contacts in the OU have been processed."
