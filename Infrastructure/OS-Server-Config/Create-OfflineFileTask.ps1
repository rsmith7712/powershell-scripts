<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 10/25/2017
    Organization: Domain, Inc.
    Filename: Create-OfflineFileTask.ps1
    =========================================================
    .DESCRIPTION
        Creates a task on each computer to check and disabled offline files

    .VERSION INFO
        v1 - Intial script Build
#>

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\Create-OfflineFileTask_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force | Out-Null
Add-Content $Script:Logfile "Computer, Status"
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$message"
}

# ----------------------------------------------------------------------------------------------
# Variables

#$computers = (Get-ADComputer -Filter * -SearchBase "ou=corporate computers,dc=domain,dc=com").name
$computers = read-host "enter computer name"

# ----------------------------------------------------------------------------------------------
# Script

foreach($computer in $computers)
{

#Verify computer is online
    if(!(test-connection -ComputerName $computer -Quiet -count 2))
    {
        Append-Log "$computer, Offline"
        Write-Host "$computer - Offline" -ForegroundColor Red
        continue
    }
    else 
    {
        #verify scripts folder, if not exist create it
        $destinationfolder = "\\$computer\C$\scripts"
        if(!(Test-Path -Path $destinationfolder))
        {
            New-Item -Path $destinationfolder -ItemType Directory -Force | Out-Null
        }

        $scriptpath = "C:\temp\check-offlinefiles.ps1"
        $destinationpath = "\\$computer\C$\...\check-offlinefiles.ps1"
        #copy script
        Copy-Item -Path $scriptpath -Destination $destinationpath -Force

        #create task
        schtasks.exe /Create /S $computer /RU "domain\opsadmin" /RP "<password>" /TR "powershell.exe -executionpolicy bypass -file C:\temp\check-offlinefiles.ps1" /SC HOURLY /TN "Check-OfflineFiles" /SD 10/26/2017 /ST 07:00 /F | Out-Null

        Append-Log "$computer, Operation Completed"
        Write-Host "$computer - Operation Completed" -ForegroundColor Green
    }
}