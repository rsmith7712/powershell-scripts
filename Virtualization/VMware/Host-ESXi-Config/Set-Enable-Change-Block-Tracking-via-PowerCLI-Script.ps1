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
    Set-Enable-Change-Block-Tracking-via-PowerCLI-Scipt.ps1

.DESCRIPTION
    Enables Change Block Tracking (CBT) on multiple virtual machines and forces it to take effect (snapshot cycle) via PowerCLI.

.FUNCTIONALITY
    Enables Change Block Tracking on VMs.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#

ISSUE: 
    You need to enable Change Block Tracking (CBT)
    on numerous virtual machines and have it take
    effect immediately.

BACKGROUND: 
    Enabling change block tracking does not take
    effect immediately and requires a suspend/resume
    or snapshot create/delete.  This process of
    changing the CBT setting and activating the change
    becomes incredibly time consuming.

SOLUTION: 
    Enable Change Block Tracking via PowerCLI Script

    Copy the below txt and paste into a text file with
    extension .ps1.  Place this file in an easy to
    browse to location for example c:\CBT-SCRIPT


RESOURCE URL
    https://enterpriseit.co/vmware/enable-change-block-tracking-via-powercli-scipt/
#>



# remember to connect to VCenter server: Connect-VIServer -Server vcenter01
Connect-VIServer "srvvcenterp.example.com"

#show current change block tracking status
Get-VM | Get-View | Sort Name | Select Name, @{N="ChangeTrackingStatus";E={$_.Config.ChangeTrackingEnabled}}

$targets = Get-VM | Select Name, @{N="CBT";E={(Get-View $_).Config.ChangeTrackingEnabled}} | WHERE {$_.CBT -like "False"}
ForEach ($target in $targets) {
 $vm = $target.Name
 Get-VM $vm | Get-Snapshot | Remove-Snapshot -confirm:$false
 $vmView = Get-vm $vm | get-view
 $vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
 $vmConfigSpec.changeTrackingEnabled = $true
 $vmView.reconfigVM($vmConfigSpec)
 New-Snapshot -VM (Get-VM $vm ) -Name "CBTSnap"
 Get-VM $vm | Get-Snapshot -Name "CBTSnap" | Remove-Snapshot -confirm:$false
}

#show change block tracking status again
Get-VM | Get-View | Sort Name | Select Name, @{N="ChangeTrackingStatus";E={$_.Config.ChangeTrackingEnabled}}