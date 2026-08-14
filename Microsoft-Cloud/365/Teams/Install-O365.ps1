<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 9/8/2017
    Organization: Domain, Inc.
    Filename: Install-O365.ps1
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

powershell -command 'Start-Process -FilePath "\\SERVER\SHARE\...\Install.bat" -Credential $DomainCred -Wait -WindowStyle Hidden'