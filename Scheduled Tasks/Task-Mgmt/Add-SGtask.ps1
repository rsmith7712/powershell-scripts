# LEGAL
<# LICENSE
    MIT License, Copyright 2015 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the “Software”),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
#>
# GENERAL SCRIPT INFORMATION
<#
.NAME
    Add-SGtask.ps1

.SYNOPSIS
  Adds a scheduled task to kick off a batch file.
 
.DESCRIPTION
  Adds a scheduled task to kick off a batch file using a list of stores and AD.
  
.NOTES
  Version:        1.0
  Author:         user26
  Creation Date:  11/30/2015
  Purpose/Change: Initial Script Development

.HISTORY

.FUNCTIONALITY
    Adds a scheduled task to kick off a batch file using a list of stores and AD.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#$ListNumber=$args[0]
$StoreList = Get-Content "\\srv\orgshare\...\StoreList_PCs.txt"
$ScriptSourceDir = "\\srv\orgshare\...\Install-BackOffice60.ps1"
$LogFile = "\\srv\orgshare\...\Add-Task-StoreComputers.CSV"
If(!(Test-Path $LogFile)){
	New-Item $LogFile -type "File"
	}

Add-Content -Path $LogFile -Value "Machine Name,Network State,New Task Status"

If($StoreList -eq $Null){
    Write-Host "No List Number Specified. Exiting."
    Start-Sleep 10
    Exit
    }

ForEach ($Store in $StoreList){
	#Queries AD for a list of Ticketing Computers and adds the task.
	$GetPC1 = Get-ADComputer -LDAPFilter "(name=$Store*)" -SearchBase "OU=Store Jumpstart Computers,OU=Store Computers,DC=DOMAIN,DC=com"
    $GetPC2 = Get-ADComputer -LDAPFilter "(name=$Store*)" -SearchBase "OU=Store Computers,OU=Store Computers,DC=DOMAIN,DC=com"
    $GetPC3 = Get-ADComputer -LDAPFilter "(name=$Store*)" -SearchBase "OU=Store Additional Computers,OU=Store Computers,DC=DOMAIN,DC=com"
    
    $PC1 = $GetPC1.name
    $PC2 = $GetPC2.name
    $PC3 = $GetPC3.name

    ForEach($PC in $PC1){
        If(Test-Connection -CN $PC -Quiet){
            #Copy-Item -Path $ScriptSourceDir -Destination "\\$PC\c$\Scripts" -force
          
            #Creates the new scheduled Task
			SCHTASKS /create /s $PC /TN "BO_60_Installer" /SC "Once" /RU "domain\orgsvc" /RP "<password>" /SD "01/01/2016" /ST "23:00" /TR "C:\Software\GlobalStore\gsaddon\DOMAIN2060Drop2\ORGUpgradeApp.exe ORGSVC <password> GlobalSTORE domainsa <password> SRV-ORG-SQL1 ORGSupportCenter domainsa <password> /REBOOT=10 /NOTIFY=1" /f
            $Check = schtasks /query /s $PC /TN "BO_60_Installer" /fo CSV | ConvertFrom-CSV
			If($Check -eq $Null){
				Add-Content -Path $LogFile -Value "$PC,Online,Failed to Add"
				}
			Else{
				Add-Content -Path $LogFile -Value "$PC,Online,$($Check.status)"
				}
        
			}
		Else{
			Add-Content -Path $LogFile -Value "$PC,Offline"
			}
        }
	
    ForEach($PC in $PC2){
        If(Test-Connection -CN $PC -Quiet){
            #Copy-Item -Path $ScriptSourceDir -Destination "\\$PC\c$\Scripts" -force
        
            #Creates the new scheduled Task
            SCHTASKS /create /s $PC /TN "BO_60_Installer" /SC "Once" /RU "domain\orgsvc" /RP "<password>" /SD "01/01/2016" /ST "23:00" /TR "C:\Software\GlobalStore\gsaddon\DOMAIN2060Drop2\ORGUpgradeApp.exe ORGSVC <password> GlobalSTORE domainsa <password> SRV-ORG-SQL1 ORGSupportCenter domainsa <password> /REBOOT=10 /NOTIFY=1" /f
            $Check = schtasks /query /s $PC /TN "BO_60_Installer" /fo CSV | ConvertFrom-CSV
			If($Check -eq $Null){
				Add-Content -Path $LogFile -Value "$PC,Online,Failed to Add"
				}
			Else{
				Add-Content -Path $LogFile -Value "$PC,Online,$($Check.status)"
				}
        
			}
		Else{
			Add-Content -Path $LogFile -Value "$PC,Offline"
			}
        }

    ForEach($PC in $PC3){
        If(Test-Connection -CN $PC -Quiet){
            #Copy-Item -Path $ScriptSourceDir -Destination "\\$PC\c$\Scripts" -force
        
            #Creates the new scheduled Task
			SCHTASKS /create /s $PC /TN "BO_60_Installer" /SC "Once" /RU "domain\orgsvc" /RP "<password>" /SD "01/01/2016" /ST "23:00" /TR "C:\Software\GlobalStore\gsaddon\DOMAIN2060Drop2\ORGUpgradeApp.exe ORGSVC <password> GlobalSTORE domainsa <password> SRV-ORG-SQL1 ORGSupportCenter domainsa <password> /REBOOT=10 /NOTIFY=1" /f
            $Check = schtasks /query /s $PC /TN "BO_60_Installer" /fo CSV | ConvertFrom-CSV
			If($Check -eq $Null){
				Add-Content -Path $LogFile -Value "$PC,Online,Failed to Add"
				}
			Else{
				Add-Content -Path $LogFile -Value "$PC,Online,$($Check.status)"
				}
        
			}
		Else{
			Add-Content -Path $LogFile -Value "$PC,Offline"
			}
        }
	}