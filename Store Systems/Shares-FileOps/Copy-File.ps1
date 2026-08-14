<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: XX/XX/XXXX
    Organization: Domain, Inc.
    Filename: __TEMPLATE__.ps1
    =========================================================
    .DESCRIPTION
        [ENTER A BRIEF DESCRIPTION OF SCRIPT AND ITS PURPOSE]

    .VERSION INFO
        [ENTER ANY CHANGES MADE HERE]
#>

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\Copy-file_$stamp.csv"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "Computer, status"
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$message"
}

# ----------------------------------------------------------------------------------------------
# Variables

$computers = (Get-ADComputer -SearchBase "ou=store computers,ou=store computers,dc=domain,dc=com" -Filter *).name

# ----------------------------------------------------------------------------------------------
# Script

foreach($computer in $computers)
{
    Copy-Item -Path "C:\temp\STBackup.bat" -Destination "\\$computer\C$\...\STBackup.bat" -Force
    if($? -eq $false)
    {
        Append-Log "$computer, File Not Updated"
    }
    else 
    {
        Append-Log "$computer, File Copied"
    }
}