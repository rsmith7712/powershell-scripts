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
    Test-Ideas-Notepad.ps1

.DESCRIPTION
    Scratch/notepad of variables for a server rename and static network configuration (ideas file).

.FUNCTIONALITY
    Scratch network-configuration variables.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>



#$currentname = $env:computername
#$newname = "SRVDFSNS03p"
#$domainname = "example.com"
#$OU = "OU=FileServers,OU=Production,OU=WindowsServers,OU=SITE1,OU=Servers,DC=domain,DC=com"
$IPAddress = "0.0.0.0"
$Gateway = "0.0.0.0"
$InterfaceAlias = "vmxnet3 Ethernet Adapter"
$PrefixLen = "255.0.0.0"
$DNSPri = "0.0.0.0"
$DNSSec = "0.0.0.0"

New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $IPAddress -DefaultGateway $Gateway -PrefixLength $PrefixLen
Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddress ($DNSPri,$DNSSec)
#Add-Computer -DomainName $domainname -Credential (Get-Credential) -ComputerName $currentname -NewName $newname -OUPath $OU




#$currentname = $env:computername
#$newname = "SRVWinFS03p"
#$domainname = "example.com"
#$OU = "OU=FileServers,OU=Production,OU=WindowsServers,OU=SITE1,OU=Servers,DC=domain,DC=com"
$IPAddress = "0.0.0.0"
$Gateway = "0.0.0.0"
$InterfaceAlias = "vmxnet3 Ethernet Adapter"
$PrefixLen = "255.0.0.0"
$DNSPri = "0.0.0.0"
$DNSSec = "0.0.0.0"

New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $IPAddress -DefaultGateway $Gateway -PrefixLength $PrefixLen
Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddress ($DNSPri,$DNSSec)
#Add-Computer -DomainName $domainname -Credential (Get-Credential) -ComputerName $currentname -NewName $newname -OUPath $OU