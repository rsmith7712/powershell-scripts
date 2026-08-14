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
    012-Set-Domain-and-OU-SITE1-WinSvr-Prod_2_2.ps1

.DESCRIPTION
    Joins the current server to the domain and places it in the production Windows Servers OU (with a commented-out rename/IP template).

.FUNCTIONALITY
    Joins a server to the domain in a production OU.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>


$domainname = example.com
$currentname = $env:computername
$OU = "OU=Production,OU=WindowsServers,OU=SITE1,OU=Servers,DC=domain,DC=com"

Add-Computer -DomainName $domainname -Credential (Get-Credential) -ComputerName $currentname -OUPath $OU


<#

$newname = "<new server name>"
$domainname = example.com
$IPAddress = "<ipaddress>"
$Gateway = "<gateway>"
$InterfaceAlias = "Ethernet0"
$PrefixLen = "<prefix>"
$DNSPri = "0.0.0.0"
$DNSSec = "0.0.0.0"

#New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $IPAddress -DefaultGateway $Gateway -PrefixLength $PrefixLen
#Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddress ($DNSPri,$DNSSec)
#Add-Computer -DomainName $domainname -Credential (Get-Credential) -ComputerName $currentname -NewName $newname -OUPath $OU

#>