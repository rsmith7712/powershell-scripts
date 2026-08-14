<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: XX/XX/XXXX
    Organization: Domain, Inc.
    Filename: ReportFixDeploy.ps1
    =========================================================
    .DESCRIPTION
        [ENTER A BRIEF DESCRIPTION OF SCRIPT AND ITS PURPOSE]

    .VERSION INFO
        [ENTER ANY CHANGES MADE HERE]
#>

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\ReportFixDeploy_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "Computer, bat, ps1"
function Append-Log($message)
{
	Add-Content $Script:LogFile "$message"
}

# ----------------------------------------------------------------------------------------------
# Variables

$computers = (Get-ADComputer -SearchBase "ou=store computers,ou=store computers,dc=domain,dc=com" -Filter *).name
$computers += (Get-ADComputer -SearchBase "ou=store jumpstart computers,ou=store computers,dc=domain,dc=com" -Filter *).name
$computers += (Get-ADComputer -SearchBase "ou=store additional computers,ou=store computers,dc=domain,dc=com" -Filter *).name
#$batpath = "\\$computer\C$\...\ContentDelivery.bat"
#$ps1path = "\\$computer\C$\...\Sync-SPreports.ps1"

# ----------------------------------------------------------------------------------------------
# Script

foreach($computer in $computers)
{
    copy-item -Path C:\temp\ContentDelivery.bat -Destination \\$computer\C$\...\ContentDelivery.bat -Force
    if($? -eq $true)
    {
        $batstatus = "bat copied"
    }
    else 
    {
        $batstatus = "bat not copied"
    }
    Copy-Item -Path C:\temp\Sync-SPreports.ps1 -Destination \\$computer\C$\...\Sync-SPreports.ps1 -Force
    if($? -eq $true)
    {
        $ps1status = "ps1 copied"
    }
    else 
    {
        $ps1status = "ps1 not copied"
    }
    Append-Log "$computer, $batstatus, $ps1status"
}