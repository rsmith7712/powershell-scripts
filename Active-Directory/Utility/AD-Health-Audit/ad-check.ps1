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
    ad-check.ps1

.DESCRIPTION
    Checks Active Directory health: domain-controller replication status and the state of critical AD services.

.FUNCTIONALITY
    Checks AD replication and critical service health.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#Requires -RunAsAdministrator

#Import Module
Import-Module ActiveDirectory

#Query domain controllers for replication status
repadmin /replsum

#Ensure (4) system components that are critical for running AD Domain Services efficiently
$Services = 'DNS','DFS Replication','Intersite Messaging','Kerberos Key Distribution Center','NetLogon','Active Directory Domain Services'
ForEach ($Service in $Services){
    $GS = Get-Service -ComputerName 'srv' | Where-Object {$_.Name -eq $Service}
    If ($GS.Status -eq "Running"){
        Write-Host "$Service is in running state on server" -ForegroundColor Green}
        Else{
        Write-Host "$Service is in the stopped state on server" -ForegroundColor Red}
        }

#Query domain controllers ensuring DNS is working properly
DCDiag /Test:DNS -s:srv /e /v 

#Query Event Logs for ID 2886 - Indicates that LDAP signing is not enabled
Get-EventLog -LogName Security -InstanceId 2886

#Query Event Logs for ID 2887 if 2886 is detected
#Get-EventLog -LogName Security -InstanceID 2887

#Query Event Logs for ID 2889 - Indicates insecure bind is being made
#Get-EventLog -LogName Security -InstanceID 2889
