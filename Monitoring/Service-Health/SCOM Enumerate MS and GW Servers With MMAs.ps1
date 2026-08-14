# Script to enumerate SCOM MS & GW Servers and count the MMA's reporting to them
# Made by Marnix Wolf
# (c) 08-06-2015, Version 1.1
# Source: http://blogs.technet.com/b/jimmyharper/archive/2010/07/23/powershell-commands-to-configure-gateway-server-agent-failover.aspx

#Import SCOM 2012 Module & connect to Management Server
Import-Module OperationsManager
New-SCManagementGroupConnection -ComputerName FQDN OF ONE OF YOUR OM12 R2 MS SERVERS 

#Tests whether the file 'C:\Server Management\Enum_MS_GW_MMA.txt' exists. When found it will be deleted. 
$File = Test-Path -Path "C:\Server Management\Enum_MS_GW_MMA.txt"
If ($File -eq 'True')
#File found and deleted 
{
Write-Host "File 'C:\Server Management\Enum_MS_GW_MMA.txt' found and deleted."
Remove-Item 'C:\Server Management\Enum_MS_GW_MMA.txt' | Out-Null
}
Else 
#File not present. Check now for presence of folder 'C:\Server Management'
{
Write-Host "File 'C:\Server Management\Enum_MS_GW_MMA.txt' not found. No further actions required."
    If (Test-Path -Path "C:\Server Management")
    #File not found but folder is present. No furter actions required.
    {}
    Else
    #File not found and folder is missing. Folder is created.
    {
    md "C:\Server Management" | Out-Null
    }
}

#Total count MS & GW servers
$AmountGWs = (Get-SCOMManagementServer | where {$_.IsGateway -eq $true}).count
$AmountMSs = (Get-SCOMManagementServer | where {$_.IsGateway -eq $false}).count 

#Get all SCOM Management Servers of the Management Group
$MgtSrvrs = Get-SCOMManagementServer | Sort DisplayName

#Enumerate all Microsoft Monitoring Agents per SCOM Management Server
foreach ($MgtSrvr in $MgtSrvrs)

{
$TotalAgentsPerMSCount = (Get-SCOMAgent -ManagementServer $MgtSrvr).count
$MgtSrvrName = $MgtSrvr| foreach {$_.DisplayName}

#Notify user this particular SCOM Management Server has NO Microsoft Monitoring Agents reporting to it
If ($TotalAgentsPerMSCount -eq $null )
    {
        #Differentiate between SCOM MS & SCOM GW Server
        If ($GW = $MgtSrvr | where {$_.IsGateway -eq $true})
        { 
        #SCOM GW Server identified
        $ServerType = "SCOM Gateway Server"
        }
        Else
        {
        #SCOM MS Server identified
        $ServerType = "SCOM Management Server"
        }
    Write-Host "$ServerType  " -NoNewline; Write-Host "$MgtSrvrName" -f Red -NoNewline; Write-Host " has" -NoNewline; Write-Host " NO" -f Red -NoNewline; Write-Host " Microsoft Monitoring Agents reporting to it."
    Write-Output "$ServerType $MgtSrvrName has NO Microsoft Monitoring Agents reporting to it." | Out-File "C:\Server Management\Enum_MS_GW_MMA.txt" -append
    
    }

#Notify user how many Microsoft Monitoring Agents are reporting to this particular SCOM Management Server   
Else
    {
        #Differentiate between SCOM MS & SCOM GW Server
        If ($GW = $MgtSrvr | where {$_.IsGateway -eq $true})
        { 
        #SCOM GW Server identified
        $ServerType = "SCOM Gateway Server"
        }
        Else
        {
        #SCOM MS Server identified
        $ServerType = "SCOM Management Server"
        }
Write-Host "$ServerType  " -NoNewline; Write-Host "$MgtSrvrName" -f Green -NoNewline; Write-Host " has "-NoNewline; Write-Host $TotalAgentsPerMSCount -f Green -NoNewline; Write-Host " Microsoft Monitoring Agent(s) reporting to it."
Write-Output "$ServerType $MgtSrvrName has $TotalAgentsPerMSCount Microsoft Monitoring Agent(s) reporting to it." | Out-File "C:\Server Management\Enum_MS_GW_MMA.txt" -append
    }
}

#Display Primary and Failover Management Servers for all Gateway Servers 
If ($AmountGWs-eq "0" )
    {
    Write-Host "`nNo SCOM Gateway Servers detected."
    }
Else
    {
    Write-Host "`nAdditional information SCOM Gateway Servers (this information is only shown on screen!):" 
    $GWs = Get-SCOMManagementServer | where {$_.IsGateway -eq $true} 
    $GWs | sort | foreach { 
    Write-Host "`nSCOM Gateway Server: " -NoNewline; Write-Host $_.Name -f Green; Write-Host "> Primary MS: " -NoNewline; Write-Host ($_.GetPrimaryManagementServer()).ComputerName -f Cyan 
    $failoverServers = $_.getFailoverManagementServers() 
    foreach ($managementServer in $failoverServers) { 
    Write-Host "> Failover MS: " -NoNewline; Write-Host ($managementServer.ComputerName) -f Cyan
    }
} 
} 

#Count the total of Microsoft Monitoring Agents present in this MG and notify the user
$TotalAgentMGCount = (Get-SCOMAgent).count
$MGName = Get-SCOMManagementGroup | foreach {$_.Name}
If ($AmountGWs-eq "0" )
    {
    Write-Host "`nIn total there are " -NoNewline; Write-Host $TotalAgentMGCount -f Green -NoNewline; Write-Host " MMA's reporting to SCOM MG "-NoNewline; Write-Host $MGName -f Green -NoNewline; Write-Host ", containing " -NoNewline; Write-Host $AmountMSs -f Green -NoNewline; Write-Host " SCOM Management Servers. No SCOM Gateway Servers detected."
    Write-Output `n | Out-File "C:\Server Management\Enum_MS_GW_MMA.txt" -Append; "In total there are $TotalAgentMGCount MMA's reporting to SCOM MG $MGName, containing $AmountMSs SCOM Management Servers. No SCOM Gateway Servers detected." | Out-File "C:\Server Management\Enum_MS_GW_MMA.txt" -append
    }
Else
    {
    Write-Host "`nIn total there are " -NoNewline; Write-Host $TotalAgentMGCount -f Green -NoNewline; Write-Host " MMA's reporting to SCOM MG "-NoNewline; Write-Host $MGName -f Green -NoNewline; Write-Host ", containing " -NoNewline; Write-Host $AmountMSs -f Green -NoNewline; Write-Host " SCOM Management Servers & "-NoNewline; Write-Host $AmountGWs -f Green -NoNewline; Write-Host " SCOM Gateway Servers."
    Write-Output `n | Out-File "C:\Server Management\Enum_MS_GW_MMA.txt" -Append; "In total there are $TotalAgentMGCount MMA's reporting to SCOM MG $MGName, containing $AmountMSs SCOM Management Servers & $AmountGWs SCOM Gateway Servers." | Out-File "C:\Server Management\Enum_MS_GW_MMA.txt" -append
    }
#Open text file 'C:\Server Management\Enum_MS_GW_MMA.txt'
Invoke-Item "C:\Server Management\Enum_MS_GW_MMA.txt"

#End of script