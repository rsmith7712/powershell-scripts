<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 4/19/2017
    Organization: Domain, Inc.
    Filename: Bitlocker_Win10.ps1
    =========================================================
    .RESOURCES USED
        https://blogs.technet.microsoft.com/heyscriptingguy/2015/05/26/powershell-and-bitlocker-part-2/
        https://blogs.technet.microsoft.com/heyscriptingguy/2015/05/25/powershell-and-bitlocker-part-1/

    .DESCRIPTION
        Script activates bitlocker on windows 10 devices.

    .VERSION INFO
        v.1 - Intitial script build
#>

# ----------------------------------------------------------------------------------------------
# Logging

$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$stamp2 = get-date
$Script:Logfile = "C:\temp\DVR_SETUP_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "BitLocker Setup started on $stamp2"
function Append-Log($message)
{
	Add-Content $Script:LogFile "$message"
}

# ----------------------------------------------------------------------------------------------
# Variables

$TPM = Get-WmiObject -Namespace ROOT\CIMV2\Security\MicrosoftTpm -Class win32_tpm
$password = "<password>"
$TPMPassword = $TPM.ConvertToOwnerAuth($password).OwnerAuth

# ----------------------------------------------------------------------------------------------
# Script

if($TPM.IsEnabled().isenabled -eq "False"){
    $TPM.enable()
}
if($TPM.isactivated().isactivated -eq "False"){
    $TPM.Activate()
}
if($TPM.isowned().isowned -eq "True"){
    $TPM.clear()
    $TPM.TakeOwnership($password)
}
else {
    $TPM.TakeOwnership($password)
}

