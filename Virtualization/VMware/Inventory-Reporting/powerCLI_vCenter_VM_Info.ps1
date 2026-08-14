# LEGAL
<# LICENSE
    MIT License, Copyright 2022 Richard Smith

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
    powerCLI_vCenter_VM_Info.ps1

.DESCRIPTION
    Collects detailed virtual-machine information (CPU, memory, NICs, datastore, tools, etc.) from vCenter via Get-View.

.FUNCTIONALITY
    Reports detailed VM information from vCenter.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$report = @()


foreach($vm in Get-View -ViewType Virtualmachine){

    $vms = "" | Select-Object VMName, Hostname, IPAddress, OS, Boottime, VMState, TotalCPU, CPUAffinity,

         CPUHotAdd, CPUShare, CPUlimit, OverallCpuUsage, CPUreservation, TotalMemory, MemoryShare, MemoryUsage,

         MemoryHotAdd, MemoryLimit, MemoryReservation, Swapped, Ballooned, Compressed, TotalNics, ToolsStatus,

          ToolsVersion, HardwareVersion, TimeSync, CBT, Portgroup, VMHost, ProvisionedSpaceGB, UsedSpaceGB, Datastore,

          Notes, FaultTolerance, SnapshotName, SnapshotDate, SnapshotSizeGB, Owner, NB_last_backup

         

    $vms.VMName = $vm.Name

    $vms.Hostname = $vm.guest.hostname

    $vms.IPAddress = $vm.guest.ipAddress

    $vms.OS = $vm.Config.GuestFullName

    $vms.Boottime = $vm.Runtime.BootTime

    $vms.VMState = $vm.summary.runtime.powerState

    $vms.TotalCPU = $vm.summary.config.numcpu

    $vms.CPUAffinity = $vm.Config.CpuAffinity

    $vms.CPUHotAdd = $vm.Config.CpuHotAddEnabled

    $vms.CPUShare = $vm.Config.CpuAllocation.Shares.Level

    $vms.TotalMemory = $vm.summary.config.memorysizemb

    $vms.MemoryHotAdd = $vm.Config.MemoryHotAddEnabled

    $vms.MemoryShare = $vm.Config.MemoryAllocation.Shares.Level

    $vms.TotalNics = $vm.summary.config.numEthernetCards

    $vms.OverallCpuUsage = $vm.summary.quickStats.OverallCpuUsage

    $vms.MemoryUsage = $vm.summary.quickStats.guestMemoryUsage

    $vms.ToolsStatus = $vm.guest.toolsstatus

    $vms.ToolsVersion = $vm.config.tools.toolsversion

    $vms.TimeSync = $vm.Config.Tools.SyncTimeWithHost

    $vms.HardwareVersion = $vm.config.Version

    $vms.MemoryLimit = $vm.resourceconfig.memoryallocation.limit

    $vms.MemoryReservation = $vm.resourceconfig.memoryallocation.reservation

    $vms.CPUreservation = $vm.resourceconfig.cpuallocation.reservation

    $vms.CPUlimit = $vm.resourceconfig.cpuallocation.limit

    $vms.CBT = $vm.Config.ChangeTrackingEnabled

    $vms.Swapped = $vm.Summary.QuickStats.SwappedMemory

    $vms.Ballooned = $vm.Summary.QuickStats.BalloonedMemory

    $vms.Compressed = $vm.Summary.QuickStats.CompressedMemory

    $vms.Portgroup = Get-View -Id $vm.Network -Property Name | select -ExpandProperty Name

    $vms.VMHost = Get-View -Id $vm.Runtime.Host -property Name | select -ExpandProperty Name

    $vms.ProvisionedSpaceGB = [math]::Round(($vm.Summary.Storage.Committed + $vm.Summary.Storage.UnCommitted)/1GB,2)

    $vms.UsedSpaceGB = [math]::Round($vm.Summary.Storage.Committed/1GB,2)

    $vms.Datastore = $vm.Config.DatastoreUrl[0].Name

    $vms.Notes = $vm.Config.Annotation

    $vms.FaultTolerance = $vm.Runtime.FaultToleranceState

    $vms.SnapshotName = &{$script:snaps = Get-Snapshot -VM $vm.Name; $script:snaps.Name -join ','}

    $vms.SnapshotDate = $script:snaps.Created -join ','

    $vms.SnapshotSizeGB = $script:snaps.SizeGB -join ','

    $vms.Owner = (Get-TagAssignment -Category Owner -Entity $vm.Name).Tag.Name

    $vms.NB_last_backup =  Get-VM -Name $vm.Name | select -ExpandProperty Customfields | where{$_.Key -eq 'Last Backup'} | select -ExpandProperty Value

    $Report += $vms

}

 

$report | Export-Csv C:\temp\vCenter_VM_Info.csv