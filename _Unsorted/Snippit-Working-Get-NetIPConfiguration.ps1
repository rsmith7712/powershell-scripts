# LEGAL
<# LICENSE
    MIT License, Copyright 2025 Richard Smith

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
    Snippit-Working-Get-NetIPConfiguration.ps1

.DESCRIPTION
    This script is designed to provide a working code snippit for using the
    Get-NetIPConfiguration cmdlet in PowerShell. The script includes an example of how
    to use the Get-NetIPConfiguration cmdlet to retrieve information about IP configuration
    on a local or remote computer.

.FUNCTIONALITY
    This script is designed to provide a working code snippit for using the
    Get-NetIPConfiguration cmdlet in PowerShell. The script includes an example of how
    to use the Get-NetIPConfiguration cmdlet to retrieve information about IP configuration
    on a local or remote computer.

    The script can be modified to include additional functionality as needed.
    This script is designed to provide various code snippits for collecting
    MAC Address information using PowerShell. The script includes multiple
    solutions for retrieving MAC Address information from local and remote
    computers. The script can be modified to include additional functionality
    as needed.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>


#######################
##                   ##
##    SNIPPIT # 1    ##
##                   ##
#######################

#Out to console - Different format
Get-NetIPConfiguration | 
  Select-Object @{n='IPv4Address';e={$_.IPv4Address[0]}},
         @{n='MacAddress'; e={$_.NetAdapter.MacAddress}}

<#
EXAMPLE OUTPUT - TO THE CONSOLE:

Get-NetIPConfiguration


InterfaceAlias       : Ethernet
InterfaceIndex       : 7
InterfaceDescription : Intel(R) Ethernet Connection (4) I219-V
NetProfile.Name      : corp.symetrix.com
IPv4Address          : 192.168.150.176
IPv4DefaultGateway   : 192.168.150.1
DNSServer            : 192.168.100.8
                       192.168.100.9

InterfaceAlias       : Wi-Fi
InterfaceIndex       : 19
InterfaceDescription : Intel(R) Dual Band Wireless-AC 8265
NetAdapter.Status    : Disconnected


#>