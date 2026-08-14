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
    001-Get-NetAdapterInfo.ps1.txt

.DESCRIPTION
    Lists all network adapters (name and interface index) to identify the target adapter.

.FUNCTIONALITY
    Lists network adapters and their interface indexes.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>


#List all adapters - Take note of desired network interface index
Get-NetAdapter -Name *

#Remove any IP config from adapter
#Remove-NetIPAddress -InterfaceIndex 6 -Confirm:$false

#Remove any DNS config from adapter
#Remove-NetRoute -InterfaceIndex 6 -Confirm:$false

#Set static IP on adapter
#New-NetIPAddress -InterfaceIndex 6 -IPAddress 0.0.0.0 -AddressFamily IPv4 -PrefixLength 8 -DefaultGateway 0.0.0.0

#Set DNS on adapter
#Set-DnsClientServerAddress -InterfaceIndex 6 -ServerAddresses ("0.0.0.0","0.0.0.0")

#Verify DNS info
#Get-DnsClientServerAddress -InterfaceIndex 6

#Verify config of adapter
#Get-NetIPConfiguration -InterfaceIndex 6 -Detailed

