<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: XX/XX/XXXX
    Organization: Domain, Inc.
    Filename: remove-tasks.ps1
    =========================================================
    .DESCRIPTION
        [ENTER A BRIEF DESCRIPTION OF SCRIPT AND ITS PURPOSE]

    .VERSION INFO
        [ENTER ANY CHANGES MADE HERE]
#>

# ----------------------------------------------------------------------------------------------
# Logging

param (
    [Parameter(Mandatory=$true)][string]$Store = ""
)

# ----------------------------------------------------------------------------------------------
# Functions

# ----------------------------------------------------------------------------------------------
# Variables

$computers = (get-adcomputer -LDAPFilter "(name=$Store*)" -SearchBase "OU=Store Computers,DC=DOMAIN,DC=com").name

# ----------------------------------------------------------------------------------------------
# Script

foreach($computer in $computers)
{
    schtasks.exe /DELETE /S $computer /TN "Set-IP" /F
    schtasks.exe /DELETE /S $computer /TN "Set-DHCP" /F
}