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
$Script:Logfile = "C:\temp\offlinefiles_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "computer, status"
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$message"
}

# ----------------------------------------------------------------------------------------------
# Variables

$computers = (Get-ADComputer -Filter * -SearchBase "ou=corporate computers,dc=domain,dc=com").name

# ----------------------------------------------------------------------------------------------
# Script

foreach($computer in $computers)
{
    if(!(Test-Connection -ComputerName $computer -Quiet))
    {
        Write-Host "$computer -- offline"
        Append-Log "$computer, offline"
        continue
    }
    $check = (get-service -ComputerName $computer -Name CscService).Status

    if($check -eq "Running")
    {
        Get-Service -ComputerName $computer -Name CscService | Stop-Service | Set-Service -StartupType Disabled
        Write-host "$computer -- Service stopped and disabled"
        Append-Log "$computer, stopped and disabled"
    }
    else 
    {
        Get-Service -ComputerName $computer -Name CscService | Set-Service -StartupType Disabled
        Write-host "$computer -- Service disabled"
        Append-Log "$computer, Disabled"
    }
}