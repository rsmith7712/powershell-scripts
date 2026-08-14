<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 08/31/2017
    Organization: Domain, Inc.
    Filename: Copy-Software.ps1
    =========================================================
    .DESCRIPTION
        Copies the entire contents of the software folder to a freshly images laptop.  To be used as part of image process.

    .VERSION INFO
        v1 - Initial script buildout
#>

# ----------------------------------------------------------------------------------------------
# Variables

$domainuser = "domain\opsadmin"
$domainpass = ConvertTo-SecureString "<password>" -AsPlainText -Force
$DomainCred = New-Object System.Management.Automation.PSCredential $domainuser, $domainpass

# ----------------------------------------------------------------------------------------------
# Script

New-PSDrive -Name S -PSProvider FileSystem -Root \\SERVER\SHARE\...\Laptop -Credential $DomainCred -Persist
Copy-Item -Path S:\software -Destination C:\ -Recurse -Force
#Start-Sleep -Seconds 300
Remove-PSDrive -Name S -Force