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
    Report-ESXi-VM-Information-TEST.ps1

.DESCRIPTION
    Connects to vCenter and reports each virtual machine's network adapters (VM, NIC, network) to CSV (test).

.FUNCTIONALITY
    Reports VM network adapters from vCenter.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Import PowerCLI module, Ignore Certificate Errors, and connect to VSphere servers
Import-Module VMware.PowerCLI
#Set-PowerCLIConfiguration -Scope AllUsers -ParticipateInCeip $false -InvalidCertificateAction $false
Connect-VIServer -Server "srvvcenterp.example.com" -Protocol https


Get-VM | Get-NetworkAdapter | `
Select-Object @{N=”VM”;E={$_.Parent.Name}},@{N=”NIC”;E={$_.Name}},@{N=”Network”;E={$_.NetworkName}} | `
Export-Csv “C:\Temp\Report-ESXi-VM-Information-Network.csv”


Get-VM -Name * | Get-NetworkAdapter | `
Select-Object Name,`
@{N=’vDisk’;E={($_.ExtensionData.Config.Hardware.Device | Where-Object{$_ -is [VMware.Vim.VirtualDisk]}).Count}},`
@{N=’vNIC’;E={($_.ExtensionData.Config.Hardware.Device | Where-Object{$_ -is [VMware.Vim.VirtualEthernetCard]}).Count}},`
@{N=”VM”;E={$_.Parent.Name}},`
@{N=”NIC”;E={$_.Name}},`
@{N=”Network”;E={$_.NetworkName}},`
Guest, NumCpu, CoresPerSocket, MemoryGB, ResourcePool, UsedSpaceGB, ProvisionedSpaceGB, Notes |`
Export-Csv “C:\Temp\Report-ESXi-VM-Information-Full.csv” -NoTypeInformation -NoClobber
