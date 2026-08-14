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
    004-Set-IP-Config-SRVDFSNS01P-103.ps1.txt

.DESCRIPTION
    Assigns a static IPv4 address, prefix and gateway to a network adapter (by interface index).

.FUNCTIONALITY
    Sets a static IP on an adapter.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#004-Set static IP on adapter
#New-NetIPAddress -InterfaceIndex <Adapter Index #> -IPAddress 0.0.0.0 -AddressFamily IPv4 -PrefixLength 255.0.0.0 -DefaultGateway 0.0.0.0

#New-NetIPAddress -InterfaceIndex "Ethernet0" -IPAddress 0.0.0.0 -AddressFamily IPv4 -PrefixLength 8 -DefaultGateway 0.0.0.0

New-NetIPAddress -InterfaceIndex 6 -IPAddress 0.0.0.0 -AddressFamily IPv4 -PrefixLength 8 -DefaultGateway 0.0.0.0