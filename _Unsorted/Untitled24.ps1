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
    Untitled24.ps1

.DESCRIPTION
	This script is designed to collect network adapter information from local and remote
	computers. The script includes functionality for retrieving MAC
	address, IP address, and other network adapter details, and exporting the
	information to a CSV file.

.FUNCTIONALITY
	This script is designed to collect network adapter information from local and
	remote computers. The script includes functionality for retrieving MAC
	address, IP address, and other network adapter details, and exporting the
	information to a CSV file. The script can be modified to include additional
	functionality as needed.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>

# Network Adapter(s)
		"`Network Adapter(s)"
		$props=@(
		    @{Label="Description"; Expression = {$_.Description}},
		    @{Label="IPAddress"; Expression = {$_.IPAddress}},
		    @{Label="IPSubnet"; Expression = {$_.IPSubnet}},
		    @{Label="DefaultIPGateway"; Expression = {$_.DefaultIPGateway}},
		    @{Label="MACAddress"; Expression = {$_.MACAddress}},
		    @{Label="DNSServerSearchOrder"; Expression = {$_.DNSServerSearchOrder}},
		    @{Label="DHCPEnabled"; Expression = {$_.DHCPEnabled}}
		)
		Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName . -Filter "IPEnabled = 'True'" |
		 Format-List $props