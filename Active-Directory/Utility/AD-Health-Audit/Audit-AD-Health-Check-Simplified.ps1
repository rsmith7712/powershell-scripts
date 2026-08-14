# LEGAL
<# LICENSE
    MIT License, Copyright 2017 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
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
    Audit-AD-Health-Check-Simplified.ps1

.DESCRIPTION
    Simplified Active Directory health check (replication, services, DCDiag, security events).

.FUNCTIONALITY
    Runs a simplified AD health check.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#Requires -RunAsAdministrator
<#
# report-AD-Health-Check-Query-of-Specific-Domain-Controller-Services.ps1

Format:
-Variables      = $OU, $Date, $NumberDays
-Import-Module  = ActiveDirectory
-Domain OU      = $Servers
-Rep Admin      = $RepAdmSum
-Services       = $Services
-DCDiag         = $DiagDNS
-Event Logs     = $Event2886, $Event2887, $Event2889
-Main
#>
#====================================
#Script Requires To Be Run As Admin
#====================================
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){
        Write-Output "This script needs to be run As Admin"
        Break
    }

#====================================
#Import Modules
#====================================
Import-Module ActiveDirectory

#====================================
#Domain OU
#====================================
### Query specific server
$Servers = ("srv")

#====================================
#Rep Admin: Query domainn controllers for replication status
#====================================
#Ensure domain controllers are in sync and that replication is continuous
#Summarizes the replication status of all the domain controllers across
# all domains associated within the forest. This will also display if a domain
# controller has stopped replicating as well as the last time each one
# successfully sync'd.
$RepAdmSum = repadmin /replsum srv #"DC=domain,DC=com"

#====================================
#DCDiag: Ensure DNS is working properly
#====================================
#One of the most common reasons for the non-performance of AD is DNS.
#DNS failure can in turn lead to replication failure.
$DiagDNS = DCDiag /Test:DNS /e /v /s:srv

#====================================
#Event Logs: Search domain controllers event logs for unsecured LDAP by Event ID; if 2886, then 2887; if 2887, then 2889
#====================================
<#
#Event ID 2886 in the Directory Service log indicates that LDAP signing is not enabled in your domain
$Event2886 = Get-EventLog -LogName Security -InstanceId 2886

#If clients are relying on unsigned SASL binds or LDAP simple binds over a non-SSL/TLS connection,
# an event (ID 2887) will be generated in the Directory Service log every 24 hours detailing the number
# of insecure binds performed.
$Event2887 = Get-EventLog -LogName Security -InstanceId 2887

#Event ID 2889 will be generated in the Directory Service log whenever an insecure bind is made to the DC
$Event2889 = Get-EventLog -LogName Security -InstanceId 2889
#>
#====================================
#Main
#====================================
Foreach ($Server in $Servers){
    if((Test-Connection -ComputerName $Server -Count 1 -Quiet) -ne $true){
        Write-Host "Not able to connect to $Server. Might be down or not exist" -ForegroundColor Red}
    else{
        Write-Host "Able to connect to $Server. Checking Service Status" -ForegroundColor Green

#Services - WORKING
        Foreach ($Service in $Services){
            $GS = Get-Service -ComputerName $Server | Where-Object {$_.Name -eq $Service}

            if($GS.Status -eq "Running"){
                Write-Host "$Service is in running state on $Server" -ForegroundColor Green}
            else{
                Write-Host "$Service is in the stopped state on $Server" -ForegroundColor Red}
        }
    }
}

$RepAdmSum
$DiagDNS

$Machine = "srv"
Get-Eventlog -Logname Security -ComputerName $Machine -newest 1000 |
Where-Object {$_.EventID -eq '2886'} |
Format-Table MachineName, Source, EventID -auto

#echo "If no results displayed, this is a good thing!"