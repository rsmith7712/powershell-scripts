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
    Get-Full-Information-About-VM-List.ps1

.DESCRIPTION
    Generates a full information report for a list of virtual machines from vCenter via PowerCLI to CSV.

.FUNCTIONALITY
    Reports full VM information to CSV.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#
.NAME
    Get-Full-Information-About-VM-List.ps1

.PURPOSE
    Generate a custom report via VMware PowerCLI console session

.NOTES
    Add vCenter connection with authentication
    Add single and multiple targeting
    Add user options menu
    Add check for C:\Temp folder; If not there, create it
    Add export results to CSV

.INITIAL SOURCE URL
https://arabitnetwork.com/2018/07/31/for-vmware-admins-day-to-day-useful-powercli-commands-scripts/

#>

# Import PowerCLI module, Ignore Certificate Errors, and connect to VSphere servers
Import-Module VMware.PowerCLI
#Set-PowerCLIConfiguration -Scope AllUsers -ParticipateInCeip $false -InvalidCertificateAction $false
Connect-VIServer -Server "srvvcenterp.example.com" -Protocol https


Get-VM -Name * |`
Select-Object Name,@{N=’vDisk’;E={($_.ExtensionData.Config.Hardware.Device |`
Where-Object{$_ -is [VMware.Vim.VirtualDisk]}).Count}},@{N=’vNIC’;E={($_.ExtensionData.Config.Hardware.Device |`
Where-Object{$_ -is [VMware.Vim.VirtualEthernetCard]}).Count}}, Notes, Guest, NumCpu, CoresPerSocket, MemoryGB, ResourcePool, UsedSpaceGB, ProvisionedSpaceGB |`
Export-Csv “C:\Temp\Report-ESXi-VM-Information-Full.csv”
