# LEGAL
<# LICENSE
    MIT License, Copyright 2023 Richard Smith

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
    096-DisableIPv6.ps1.txt

.DESCRIPTION
    Removes IPv6 bindings from every network interface and disables tunnel adapters via the registry.

.FUNCTIONALITY
    Disables IPv6 bindings and tunnel adapters.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

## This script will remove IPv6 Bindings from each network interface and disable all tunnel adapters

# Create collection of adapters and iterate through them to unbind IPv6
$interfaces = Get-NetAdapter
ForEach ($interface in $interfaces) {
    Disable-NetAdapterBinding -Name $interface.name -ComponentID ms_tcpip6
}

# Disable tunnel adapters
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters -Name DisabledComponents -Value 1