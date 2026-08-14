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
    Audit-AD-Health-Check-Query-of-Specific-Domain-Controller-Services.ps1

.DESCRIPTION
    Runs an Active Directory health check for specific domain controllers: replication summary, critical services, DCDiag and Directory Service security events.

.FUNCTIONALITY
    Runs an AD domain-controller health check.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#Requires -RunAsAdministrator
<#
# report-AD-Health-Check-Query-of-Specific-Domain-Controller-Services.ps1
#

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

====================================
#Script Requires To Be Run As Admin
====================================
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){
        Write-Output "This script needs to be run As Admin"
        Break
    }

====================================
#Variables
====================================
$OU = "DC=domain,DC=com"
$Date = get-date
$NumberDays = 180

====================================
#Import Modules
====================================
Import-Module ActiveDirectory

====================================
#Domain OU
====================================
### Query Active Directory Domain Organizational Unit (OU)
$Servers = Get-ADComputer -Filter * -SearchBase "OU=Domain Controllers, DC=domain, DC=com"

### Query text file for specific targets
#$Servers = Get-Content C:\temp\SList.txt ##Update List of servers in this file##

### Query specific server
#$Servers = ("srv")

====================================
#Rep Admin: Query domainn controllers for replication status
====================================
#Ensure domain controllers are in sync and that replication is continuous

#This summarizes the replication status of all the domain controllers across
# all domains associated within the forest. This will also display if a domain
# controller has stopped replicating as well as the last time each one
# successfully sync'd.

#(Include in query against all servers in target OU)
$RepAdmSum = repadmin /replsum

====================================
#Services: Specify via text file or service name
====================================
#$Services = Get-Content C:\temp\Serviceslist.txt

#(Include in query against all servers in target OU)
$Services = 'DNS','DFS Replication','Intersite Messaging','Kerberos Key Distribution Center','NetLogon','Active Directory Domain Services'

====================================
#DCDiag: Ensure DNS is working properly
====================================
#One of the most common reasons for the non-performance of AD is DNS.
#DNS failure can in turn lead to replication failure.

#(Include in query against all servers in target OU)
$DiagDNS = DCDiag /Test:DNS /e /v

====================================
#Event Logs: Search domain controllers event logs for unsecured LDAP by Event ID; if 2886, then 2887; if 2887, then 2889
====================================
#Event ID 2886 in the Directory Service log indicates that LDAP signing is not enabled in your domain
$Event2886 = Get-EventLog -LogName Security -InstanceId 2886

#If clients are relying on unsigned SASL binds or LDAP simple binds over a non-SSL/TLS connection,
# an event (ID 2887) will be generated in the Directory Service log every 24 hours detailing the number
# of insecure binds performed.
$Event2887 = Get-EventLog -LogName Security -InstanceId 2887

#Event ID 2889 will be generated in the Directory Service log whenever an insecure bind is made to the DC
$Event2889 = Get-EventLog -LogName Security -InstanceId 2889

====================================
#-Variables      = $OU, $Date, $NumberDays
#-Import-Module  = ActiveDirectory
#-Domain OU      = $Servers
#-Rep Admin      = $RepAdmSum
#-Services       = $Services
#-DCDiag         = $DiagDNS
#-Event Logs     = $Event2886, $Event2887, $Event2889
#-Main
====================================


====================================
#Main
====================================
Foreach ($Server in $Servers){
    if((Test-Connection -ComputerName $Server -Count 1 -Quiet) -ne $true){
        Write-Host "Not able to connect to $Server. Might be down or not exist" -ForegroundColor Red}
    else{
        Write-Host "Able to connect to $Server. Checking Service Status" -ForegroundColor Green
#RepAdmSum
        Foreach ($RASum in $RepAdmSum){
            $RA = Get-Service -ComputerName $Server | Where-Object {$_.Name -eq $RASum}

            if($RA.Status -eq "Running"){
                Write-Host "$RASum is in running state on $Server" -ForegroundColor Green}
            else{
                Write-Host "$RASum is in the stopped state on $Server" -ForegroundColor Red}
        }

#Services - WORKING
        Foreach ($Service in $Services){
            $GS = Get-Service -ComputerName $Server | Where-Object {$_.Name -eq $Service}

            if($GS.Status -eq "Running"){
                Write-Host "$Service is in running state on $Server" -ForegroundColor Green}
            else{
                Write-Host "$Service is in the stopped state on $Server" -ForegroundColor Red}
        }

#DiagDNS
        Foreach ($Service in $Services){
            $DD = Get-Service -ComputerName $Server | Where-Object {$_.Name -eq $Service}

            if($DD.Status -eq "Running"){
                Write-Host "$Service is in running state on $Server" -ForegroundColor Green}
            else{
                Write-Host "$Service is in the stopped state on $Server" -ForegroundColor Red}
        }

#Event2886, 2887, 2889
        Foreach ($Service in $Services){
            $EL = Get-Service -ComputerName $Server | Where-Object {$_.Name -eq $Service}

            if($EL.Status -eq "Running"){
                Write-Host "$Service is in running state on $Server" -ForegroundColor Green}
            else{
                Write-Host "$Service is in the stopped state on $Server" -ForegroundColor Red}
        }
    }
}


====================================
#Test Bed
====================================

#Query to pull all the ADUser Objects that have been inactive for greater than 180-days and export to CSV
Get-ADUser -Filter * -SearchBase $OU -Properties SAMAccountName, GivenName, SurName, LastLogonDate |
? { $_.LastLogonDate -gt $Date.AddDays(-180) } |
Select-Object SAMAccountName, GivenName, SurName, LastLogonDate | Export-Csv "c:\Temp\report-AD-HealthCheck-ADUser-Inactive-Greater180days.csv" -NoTypeInformation

#Query to pull all the ADGroup Objects that are empty and export to CSV
$Groups = Get-ADGroup -Filter { Members -notlike "*" } -SearchBase $OU | Select-Object Name, GroupCategory, DistinguishedName
$Groups | Export-Csv "C:\Temp\report-AD-HealthCheck-Empty-Groups.csv" -NoTypeInformation

#Query to pull all the ADComputer Objects that are empty and export to CSV
Get-ADComputer -Properties LastLogonDate -Filter * | Where-Object LastLogonDate -LT ($Date).AddDays(-180) |
Export-Csv "c:\Temp\report-AD-HealthCheck-Object-Inactive-Greater180days.csv" -NoTypeInformation

#Query for computers that have been inactive for greater than 180-days
Get-ADComputer -Filter * -SearchBase "DC=domain,DC=com" |
Where-Object { $_.InactiveFor -le (Get-Date).adddays(- $NumberDays) } |
Where-Object { $_.ParentContainer -notmatch "DC=domain,DC=com" } |
Select-Object Name, ParentContainer, Department, Office, Description, InactiveFor, LastLogon, AccountIsDisabled |
Export-Csv "C:\Temp\report-AD-HealthCheck-Computers-Inactive-Greater180days.csv" -noTypeInformation
