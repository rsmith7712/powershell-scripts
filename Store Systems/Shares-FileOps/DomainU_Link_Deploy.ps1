<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: XX/XX/XXXX
    Organization: Domain, Inc.
    Filename: DomainU_Link_Deploy.ps1
    =========================================================
    .DESCRIPTION
        [ENTER A BRIEF DESCRIPTION OF SCRIPT AND ITS PURPOSE]

    .VERSION INFO
        [ENTER ANY CHANGES MADE HERE]
#>

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\DomainU_Link_Deploy_$stamp.csv"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "Computer,Status,Old Shortcut Status,New Shortcut Status"
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$message"
}

# ----------------------------------------------------------------------------------------------
# Functions

function deploy_shortcut ($computer)
{
    if (!(test-connection -Count 2 -ComputerName $computer -quiet)) 
    {
        append-log "$computer,Offline"
        continue
    }
    else 
    {
        $oldpath = "\\$computer\C$\...\Start Menu\Programs\DomainU.lnk"
        if((Test-Path $oldpath) -eq $true)
        {
            Remove-Item $oldpath -Force
        }
        
        Copy-Item -path \\SERVER\SHARE\...\DomainU.ico -destination \\$computer\C$\...\DomainU.ico -Force
        
        $webpath = "\\$computer\C$\...\start menu\Programs\Domain University.lnk"
        $weburl = "https://domainuniversityonline.csod.com/"

        $wscriptshell = New-Object -ComObject wscript.shell
        $shortcut = $wscriptshell.CreateShortcut($webpath)
        $shortcut.TargetPath = "C:\Program Files (x86)\Internet Explorer\iexplore.exe"
        $shortcut.IconLocation = "C:\windows\system32\DomainU.ico,0"
        $shortcut.Arguments = $weburl
        $shortcut.Save()

        $oldtest = "\\$computer\C$\...\Start Menu\Programs\DomainU.lnk"
        if ((test-path $oldtest) -eq $true)
        {
            $oldurl = "Not Removed"
        }
        else 
        {
            $oldurl = "Removed"
        }
        $newtest = "\\$computer\C$\...\start menu\Programs\Domain University.lnk"
        if((Test-Path $newtest) -eq $true)
        {
            $newurl = "Deployed"
        }
        else 
        {
            $newurl = "Failure"
        }
        append-log "$computer,Online,$oldurl,$newurl"

    }
}

# ----------------------------------------------------------------------------------------------
# Variables

#$computers = Read-Host "Enter Computer Name"


$computers = @()
$computers += (Get-ADComputer -Filter * -SearchBase "ou=store computers,ou=store computers,dc=domain,dc=com").name
$computers += (Get-ADComputer -Filter * -SearchBase "ou=store jumpstart computers,ou=store computers,dc=domain,dc=com").name
$computers += (Get-ADComputer -Filter * -SearchBase "ou=store additional computers,ou=store computers,dc=domain,dc=com").name


#$computers = Get-Content C:\temp\computers.txt

# ----------------------------------------------------------------------------------------------
# Script

foreach($computer in $computers)
{
    deploy_shortcut $computer
}