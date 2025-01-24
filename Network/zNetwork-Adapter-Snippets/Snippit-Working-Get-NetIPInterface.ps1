# LEGAL
<# LICENSE
    MIT License, Copyright 2024 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the “Software”),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS
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
    Snippit-Working-Get-NetIPInterface.ps1

.SYNOPSIS

.FUNCTIONALITY

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts - Network-Adapter-Snippets -

#>


#######################
##                   ##
##    SNIPPIT # 1    ##
##                   ##
#######################

#Out to console
Get-NetIPInterface

<#
EXAMPLE OUTPUT - TO THE CONSOLE:

Get-NetIPInterface

ifIndex InterfaceAlias                  AddressFamily NlMtu(Bytes) InterfaceMetric Dhcp     ConnectionState PolicyStore
------- --------------                  ------------- ------------ --------------- ----     --------------- -----------
4       Local Area Connection* 12       IPv6                  1500              25 Enabled  Disconnected    ActiveStore
13      Local Area Connection* 1        IPv6                  1500              25 Disabled Disconnected    ActiveStore
1       Loopback Pseudo-Interface 1     IPv6            4294967295              75 Disabled Connected       ActiveStore
4       Local Area Connection* 12       IPv4                  1500              25 Disabled Disconnected    ActiveStore
13      Local Area Connection* 1        IPv4                  1500              25 Enabled  Disconnected    ActiveStore
7       Ethernet                        IPv4                  1500              25 Enabled  Connected       ActiveStore
19      Wi-Fi                           IPv4                  1500              25 Enabled  Disconnected    ActiveStore
1       Loopback Pseudo-Interface 1     IPv4                  1500              75 Disabled Connected       ActiveStore

#>