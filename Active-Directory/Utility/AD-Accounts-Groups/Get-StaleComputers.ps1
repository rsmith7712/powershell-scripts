 
<#
*** THIS SCRIPT IS PROVIDED WITHOUT WARRANTY, USE AT YOUR OWN RISK ***

.DESCRIPTION
	1. Search an OU for computer accounts that have not authenticated in x number of days ($days)
    2. Disable those accounts
    3. Move those disabled computer accounts to another OU ($disabledOU)
    4. Also creates a logfile of all the computers that were disabled ($logpath)

.NOTES
	File Name: Get-StaleComputers.ps1
	Author: David Hall
	Contact Info: 
		Website: www.signalwarrant.com
		Twitter: @signalwarrant
		Facebook: facebook.com/signalwarrant/
		Google +: plus.google.com/113307879414407675617
		YouTube Subscribe link: https://www.youtube.com/channel/UCgWfCzNeAPmPq_1lRQ64JtQ?sub_confirmation=1
	Requires: PowerShell Remoting Enabled (Enable-PSRemoting) 
	Tested: PowerShell Version 5, Windows Server 2012 R2

.PARAMETER
		 
.EXAMPLE
     .\Get-StaleComputers.ps1
#>


####### Edit these Variables
# Gets todays Date
$date = Get-Date

# Number of days it's been since the computer authenticated to the domain
# In my case 1 day
$days = "-30"

# Sets a description on that object so other admins know why the object was disabled
$description = "Disabled by IT on $date due to inactivity for 30+ days."

# This is the OU you are searching for Stale Computer accounts
$ou = "CN=Computers,DC=Domain,DC=com"

# This is where the disabled accounts get moved to.
$disabledOU = "OU=Disabled_Computers,DC=Domain,DC=com"

# path to the log file
$logpath = "C:\temp\stale_computers.csv"
####### Edit these Variables

# Finding Stale Computers
$findcomputers = Get-adcomputer –filter * -SearchBase $ou -properties cn, LastLogonDate | 
Where {$_.LastLogonDate –le [DateTime]::Today.AddDays($days) -and ($_.lastlogondate -ne $null) }

# Create a CSV containg all the Stale Computer Information
$findcomputers | export-csv $logpath

# Disable the Stale Computer Accounts
$findcomputers | set-adcomputer -Description $description –passthru | Disable-ADAccount

# Find all the Stale Computer Accounts we just disabled
$disabledAccounts = Search-ADAccount -AccountDisabled -ComputersOnly -SearchBase $ou

# Move the Disabled accounts to $disabledOU
$disabledAccounts | Move-ADObject -TargetPath $disabledOU