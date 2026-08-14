<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: XX/XX/XXXX
    Organization: Domain, Inc.
    Filename: Hourly_Task_Deploy.ps1
    =========================================================
    .DESCRIPTION
        Removes and recreates the HourlyTask scheduled task to allow longer run times for report sync. 

    .VERSION INFO
        v1.0 - Initial script buildout
#>

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\HourlyTask_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "Computer,Status,Task Removed,Task Created"
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$message"
}

# ----------------------------------------------------------------------------------------------
# Functions

function Remove-Task ($computer) 
{
    schtasks.exe /delete /S $computer /TN "HourlyTask" /F
    return
    <#
    if($? -eq $true)
    {
        return "Success"
    }
    else 
    {
        return "Failure"
    }
    #>
}

function Create-Task ($computer) 
{
    schtasks.exe /create /S $computer /TN "HourlyTask" /RU "domain\domainscheduler" /RP '<password>' /XML C:\temp\HourlyTask.xml
    return
    <#
    if($? -eq $true)
    {
        return "Success"
    }
    else 
    {
        return "Failure"
    }
    #>
}

# ----------------------------------------------------------------------------------------------
# Variables

#$computers = (Get-ADComputer -SearchBase "ou=store computers,ou=store computers,dc=domain,dc=com" -Filter *).Name
$computers = Read-Host "Enter Computer Name"
#$computers = Get-Content C:\temp\computers.txt

<#
$computers = @()
$computers += (Get-ADComputer -SearchBase "ou=store computers,ou=store computers,dc=domain,dc=com" -Filter *).name
$computers += (Get-ADComputer -SearchBase "ou=store jumpstart computers,ou=store computers,dc=domain,dc=com" -Filter *).name
$computers += (Get-ADComputer -SearchBase "ou=store additional computers,ou=store computers,dc=domain,dc=com" -Filter *).name
#>

# ----------------------------------------------------------------------------------------------
# Script

foreach($computer in $computers)
{
    If(!(test-connection -ComputerName $computer -count 2 -quiet))
    {
        Append-Log "$computer, Offline"
        continue
    }

    $remove = Remove-Task $computer
    $Create = Create-Task $computer
    
    Append-Log "$computer,Online,$remove,$create"
}