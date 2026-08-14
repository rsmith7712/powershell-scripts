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
    004a-Set-Adapter-Name-and-IP-FS03P-105-VMNetwork-VLAN100-DS1_3.ps1

.DESCRIPTION
    Renames a network adapter (by interface index) to 'VMNetwork-VLAN100-DS1' and assigns its static IPv4 address, prefix and gateway - per-host VM-network VLAN provisioning.

.FUNCTIONALITY
    Configures a server's VM-network VLAN adapter.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#004-Set Adapter Name

#Run to identify network adapter index number
#Get-NetAdapter

######################################### VMNetwork-VLAN100-DS1
#Run to rename adapter interface
param([int]$InterfaceIndex)  # Interface index of the target adapter - run Get-NetAdapter to find it.

Get-NetAdapter -InterfaceIndex $InterfaceIndex | Rename-NetAdapter -NewName 'VMNetwork-VLAN100-DS1'

#VMNetwork-VLAN100-DS
New-NetIPAddress -InterfaceIndex $InterfaceIndex -IPAddress 0.0.0.0 -AddressFamily IPv4 -PrefixLength 8 -DefaultGateway 0.0.0.0

#Disable IPv6
Disable-NetAdapterBinding -Name 'VMNetwork-VLAN100-DS1' -ComponentID 'ms_tcpip6'
