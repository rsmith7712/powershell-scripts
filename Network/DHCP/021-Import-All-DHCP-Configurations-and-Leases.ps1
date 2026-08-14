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
    021-Import-All-DHCP-Configurations-and-Leases.ps1.txt

.DESCRIPTION
    Imports DHCP server (v4 and v6) configuration and lease data from an XML file onto a DHCP server.

.FUNCTIONALITY
    Imports DHCP configuration and leases.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#
	This example imports the configuration and
	lease data in the specified file onto the
	DHCP server service that runs on the computer
	named dhcpserver.contoso.com. The file can
	contain DHCPv4 and DHCPv6 configuration data.
#>

Import-DhcpServer -ComputerName "dhcpserver.example.com" -File "E:\Admin\DHCP-Scope-Export\dhcpexport.xml" -BackupPath "C:\Admin\dhcpbackup\" -Leases