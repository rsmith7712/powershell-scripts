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
    Snippit-Working-Get-NetAdapter.ps1

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
Clear-Host
Get-NetAdapter | 
ForEach-Object {
        $PSitem | 
            Select-Object -Property Name, InterfaceDescription, ifIndex, Status, 
            MacAddress,  LinkSpeed,
            @{
                Name       = 'IPAddress'
                Expression = {(Get-NetIPAddress -InterfaceIndex ($PSItem).ifindex).IPv4Address}
            }
} | 
Format-Table -AutoSize

<#
EXAMPLE OUTPUT - TO THE CONSOLE:

Get-NetAdapter

Name                      InterfaceDescription                    ifIndex Status       MacAddress             LinkSpeed
----                      --------------------                    ------- ------       ----------             ---------
Npcap Loopback Adapter    Npcap Loopback Adapter                       24 Not Present  02-00-4C-4F-4F-50          0 bps
Wi-Fi                     Intel(R) Dual Band Wireless-AC 8265          19 Disconnected C2-23-D0-6C-7A-92          0 bps
Ethernet                  Intel(R) Ethernet Connection (4) I219-V       7 Up           48-2A-E3-13-E8-34         1 Gbps


#>


#######################
##                   ##
##    SNIPPIT # 2    ##
##                   ##
#######################

#Out to file
Clear-Host
Get-NetAdapter | 
ForEach-Object {
        $PSitem | 
            Select-Object -Property Name, InterfaceDescription, ifIndex, Status, 
            MacAddress,  LinkSpeed,
            @{
                Name       = 'IPAddress'
                Expression = {(Get-NetIPAddress -InterfaceIndex ($PSItem).ifindex).IPv4Address}
            }
} | 
Export-Csv -Path 'C:\Results\NicDetails.csv'

<#
EXAMPLE OUTPUT - TO A CSV:

Get-NetAdapter

Name                      InterfaceDescription                    ifIndex Status       MacAddress             LinkSpeed
----                      --------------------                    ------- ------       ----------             ---------
Npcap Loopback Adapter    Npcap Loopback Adapter                       24 Not Present  02-00-4C-4F-4F-50          0 bps
Wi-Fi                     Intel(R) Dual Band Wireless-AC 8265          19 Disconnected C2-23-D0-6C-7A-92          0 bps
Ethernet                  Intel(R) Ethernet Connection (4) I219-V       7 Up           48-2A-E3-13-E8-34         1 Gbps


#>