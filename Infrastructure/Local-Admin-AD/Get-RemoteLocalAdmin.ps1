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
    Get-RemoteLocalAdmin.ps1

.DESCRIPTION
    Queries a remote system for the members of its local Administrators group (with formatted output).

.FUNCTIONALITY
    Reports local Administrators on a remote system.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Get-RemoteLocalAdmin.ps1



#Query a remote system for members of the local admins group with some formatting
#invoke-command {net localgroup administrators} -cn srv-ads-dc01

<#
.RESULTS

Members

-------------------------------------------------------------------------------
Administrator
Domain Admins

#>


#Query a remote system for members of the local admins group with no formatting
#invoke-command {
#    net localgroup administrators | 
#    where {$_ -AND $_ -notmatch "command completed successfully"} | 
#    select -skip 4
#} -computer srv-ads-dc01

<#
.RESULTS

Administrator
Domain Admins

#>


#Create object with properties for computername, group name and members
#$members = net localgroup administrators | 
#where {$_ -AND $_ -notmatch "command completed successfully"} | 
#select -skip 4
#New-Object PSObject -Property @{
#    Computername = $env:COMPUTERNAME
#    Group = "Administrators"
#    Members=$members
#}

<#
.RESULTS

Group          Computername Members                                                            
-----          ------------ -------                                                            
Administrators SRV-ADS-DC01 {Administrator, Domain Admins, Enterprise Admins, user4-admin...}

#>


##Create object with properties for computername, group name and members and runs against multiple remote systems
$ou = "OU=Domain Servers,DC=Domain,DC=com"
$Computers = (Get-ADComputer -Filter '*' -SearchBase $ou).Name

If (test-connection -CN $Computers -Quiet){

    invoke-command -CN $Computers -ScriptBlock {
        $members = net localgroup administrators | 
        where {$_ -AND $_ -notmatch "command completed successfully"} | 
        select -skip 4
        New-Object PSObject -Property @{
            Computername = $env:COMPUTERNAME
            Group = "Administrators"
            Members = $members
        }
    } 
} Select * -ExcludeProperty RunspaceID | Export-Csv "C:\temp\RemoteLocalAdmins.csv" -NoTypeInformation

<#
.RESULTS

Group        : Administrators
Computername : SRV-ADS-LIC01
Members      : {Admin, DOMAIN\Domain Admins}

#>