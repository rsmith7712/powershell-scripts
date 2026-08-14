<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 01/03/2018
    Organization: Domain, Inc.
    Filename: LANDESK_CHECK.ps1
    =========================================================
    .DESCRIPTION
        [ENTER A BRIEF DESCRIPTION OF SCRIPT AND ITS PURPOSE]

    .VERSION INFO
        [ENTER ANY CHANGES MADE HERE]
#>

# ----------------------------------------------------------------------------------------------
# Initializations  

Import-Module -Name ActiveDirectory

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\LANDESK_CHECK_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "Computer, Status, Landesk"
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$message"
}

# ----------------------------------------------------------------------------------------------
# Functions

function Check-Landesk ($computer) 
{
    $agentcheck = (Get-Service -Name "CBA8" -ComputerName $computer).status | Out-Null
    If($agentcheck -ne $null)
    {
        Return "1"
    }
    else 
    {
        Return "0"
    }
}

function Install-Landesk ($computer) 
{
    if(!(Test-Path \\$computer\C$\...\LDMS))
    {
        New-Item -ItemType Directory -Path \\$computer\C$\...\LDMS -Force
    }
    Copy-Item \\SERVER\SHARE\ldmsagentorgregtageps.exe \\$computer\C$\...\ldmsagentorgregtageps.exe -Force
    Invoke-Command -ComputerName $computer -ScriptBlock{ 
        Copy-Item \\SERVER\SHARE\ldmsagentorgregtageps.exe \\$computer\C$\...\ldmsagentorgregtageps.exe -Force
        Write-Host "Copy Complete"
        start-process -FilePath "C:\software\ldms\ldmsagentorgregtageps.exe" -Wait
        Write-Host "Install Complete"
    }
}

# ----------------------------------------------------------------------------------------------
# Variables

$computers = Read-Host "Enter Computer Name"
#$computers = (Get-ADComputer -SearchBase "ou=store ticket computer,ou=store computers,dc=domain,dc=com" -Filter *).Name

# ----------------------------------------------------------------------------------------------
# Script

foreach ($computer in $computers)
{
    If(!(test-connection -ComputerName $computer -count 2 -quiet))
    {
        Append-Log "$computer, Offline"
        continue
    }

    $agentstatus = Check-Landesk $computer

    If($agentstatus -eq "1")
    {
        Append-Log "$computer, Online, Already Installed"
        continue
    }
    else 
    {
        Install-Landesk $computer
        $checkagent = (Get-Service -Name "CBA8" -ComputerName $computer).status
        if($checkagent -eq $null)
        {
            Append-Log "$computer, Online, Install Failed"
            continue
        }
        else 
        {
            Append-Log "$computer, Online, Installed"
            continue
        }
    }
}