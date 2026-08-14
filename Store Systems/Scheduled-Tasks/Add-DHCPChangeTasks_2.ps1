<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 06/16/2017
    Organization: Domain, Inc.
    Filename: Add-DHCPChangeTasks.ps1
    =========================================================
    .DESCRIPTION
        Changes a stores IP address to its new IP schema before a relo takes place.  Has failsafe to set back to DHCP if device
        cannot contact DNS server after X days.

    .VERSION INFO
        v1 - Initial script buildout.  Copied mostly from user46 R's Add-NetChangeTasks.ps1 script. 
#>

# ----------------------------------------------------------------------------------------------
# Parameters

param (
	[Parameter(Mandatory=$true)][string]$Store = "",
	[Parameter(Mandatory=$true)][datetime]$xChangeDate = "",
	[string]$ChangeTime = "06:00:00",
    [string]$FailSafeTime = "08:00:00"
)

# ----------------------------------------------------------------------------------------------
# Initializations

Import-Module ActiveDirectory

# ----------------------------------------------------------------------------------------------
# Functions

function Add-DHCPChangeTasks($CN)
{
	If (Test-Connection -CN $CN -Quiet)
	{
		Copy-Item -Path $script:Script1 -Destination "\\$CN\c$\Scripts" -Force
		Copy-Item -Path $script:Script2 -Destination "\\$CN\c$\Scripts" -Force
		
        #Creates the new scheduled Task
		SCHTASKS /create /s $CN /TN "Set-IP" /RU "domain\orgsvc" /RP "<password>" /XML "\\SERVER\SHARE\...\Set-IP.xml"
		SCHTASKS /create /s $CN /TN "Set-DHCP" /RU "domain\orgsvc" /RP "<password>" /XML "\\SERVER\SHARE\...\Set-DHCP.xml"
		$Check1 = schtasks /query /s $CN /TN "Set-IP" /fo CSV | ConvertFrom-CSV
		$Check2 = schtasks /query /s $CN /TN "Set-DHCP" /fo CSV | ConvertFrom-CSV
		If ($Check1 -eq $Null)
		{
			Append-Log "$CN,Online,Failed to Add"
		}
		Else
		{
			Append-Log "$CN,Online,$($Check1.status)"
		}
		If ($Check2 -eq $Null)
		{
			Append-Log "$CN,Online,,Failed to Add"
		}
		Else
		{
			Append-Log "$CN,Online,,$($Check2.status)"
		}
	}
	Else
	{
		Append-Log "$CN,Offline"
	}
}

# ----------------------------------------------------------------------------------------------
# Variables

$ChangeDate = $xChangeDate.ToString("yyyy-MM-dd")
$FailSafeDate = ($xChangeDate.adddays(3)).ToString("yyyy-MM-dd")

$script:script1 = "\\SERVER\SHARE\...\Set-IP.ps1"
$script:script2 = "\\SERVER\SHARE\...\Set-DHCP.ps1"

$computers = @()
$computers += (Get-ADComputer -LDAPFilter "(name=$Store*)" -SearchBase "OU=Store Register Computers,OU=Store Computers,DC=DOMAIN,DC=com").name
$computers += (Get-ADComputer -LDAPFilter "(name=$Store*)" -SearchBase "OU=SLC Servers,OU=Store Servers,DC=DOMAIN,DC=com").name
$computers += (Get-ADComputer -LDAPFilter "(name=$Store*)" -SearchBase "OU=Store Computers,OU=Store Computers,DC=DOMAIN,DC=com").name
$computers += (Get-ADComputer -LDAPFilter "(name=$Store*)" -SearchBase "OU=Store Jumpstart Computers,OU=Store Computers,DC=DOMAIN,DC=com").name
$computers += (Get-ADComputer -LDAPFilter "(name=$Store*)" -SearchBase "OU=Store Additional Computers,OU=Store Computers,DC=DOMAIN,DC=com").name
$computers += (Get-ADComputer -LDAPFilter "(name=$Store*)" -SearchBase "OU=Store Ticket Computer,OU=Store Computers,DC=DOMAIN,DC=com").name

#setting config file for set-ip task
$1xmltime = [string]($ChangeDate + "T" + $ChangeTime)
$1xmlpath = "\\SERVER\SHARE\...\Set-IP.xml"
$1xml = [xml](Get-Content $1xmlpath)
$1xml.task.triggers.timetrigger.startboundary = $1xmltime
$1xml.Save($1xmlpath)

#setting config file for set-DHCP task
$2xmltime = [string]($FailSafeDate + "T" + $FailSafeTime)
$2xmlpath = "\\SERVER\SHARE\...\Set-DHCP.xml"
$2xml = [xml](Get-Content $2xmlpath)
$2xml.task.triggers.timetrigger.startboundary = $2xmltime
$2xml.Save($2xmlpath)

# ----------------------------------------------------------------------------------------------
# Logging
$Script:LogFile = "\\SERVER\SHARE\...\Add-DHCPChange-$Store.CSV"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:LogFile "Machine Name,Network State,Change Task Status"
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$message"
}

# ----------------------------------------------------------------------------------------------
# Script

foreach($CN in $computers)
{
	Add-DHCPChangeTasks $CN
}