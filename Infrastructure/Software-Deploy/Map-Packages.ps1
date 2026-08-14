<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 09/11/2017
    Organization: Domain, Inc.
    Filename: Map-Packages.ps1
    =========================================================
    .DESCRIPTION
        [ENTER A BRIEF DESCRIPTION OF SCRIPT AND ITS PURPOSE]

    .VERSION INFO
        [ENTER ANY CHANGES MADE HERE]
#>

# ----------------------------------------------------------------------------------------------
# Variables

$domainuser = "domain\opsadmin"
$domainpass = ConvertTo-SecureString "<password>" -AsPlainText -Force
$DomainCred = New-Object System.Management.Automation.PSCredential $domainuser, $domainpass

# ----------------------------------------------------------------------------------------------
# Script

New-PSDrive -Name O -PSProvider FileSystem -Root \\SERVER\SHARE -Credential $DomainCred -Persist