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
    004b-Set-Adapter-Name-and-IP-FS01P-105-Storage-VLAN1291_2.ps1

.DESCRIPTION
    Renames a network adapter (by interface index) to 'Storage-VLAN1291' and assigns its static IPv4 address and prefix - per-host storage-network VLAN provisioning.

.FUNCTIONALITY
    Configures a server's storage-network VLAN adapter.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#004-Set Adapter Name

#Run to identify network adapter index number
#Get-NetAdapter

######################################### Storage-VLAN1291
#Run to rename adapter interface
Get-NetAdapter -InterfaceIndex 10 | Rename-NetAdapter -NewName 'Storage-VLAN1291'

#Storage-VLAN1291
New-NetIPAddress -InterfaceIndex 10 -IPAddress 0.0.0.0 -AddressFamily IPv4 -PrefixLength 8

#Disable IPv6
Disable-NetAdapterBinding -Name 'Storage-VLAN1291' -ComponentID 'ms_tcpip6'


#Alternative method to assign IP information is to use the Name
#Preference is to use the ifIndex number as this has reduced errors in IP assignment
#New-NetIPAddress -InterfaceIndex <ifIndex# or Name> -IPAddress 0.0.0.0 -AddressFamily IPv4 -PrefixLength 8
