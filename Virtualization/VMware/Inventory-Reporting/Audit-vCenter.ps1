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
    Audit-vCenter.ps1

.DESCRIPTION
    Connects to vCenter and audits the virtual machines in a cluster (guest, cluster and datastore details).

.FUNCTIONALITY
    Audits VMs in a vCenter cluster.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>



$vCenter = "domainvc1"
$Cluster = "SRV-VDI-CLUSTER1"

Connect-VIserver $vcenter

$AuditVM = @()
ForEach ($vm in (Get-Cluster $Cluster | Get-VM )) {
    foreach ($vmguest in @($vm | Get-VMguest)) {
        foreach ($cluster in @($vm | Get-Cluster $Cluster )) {
            foreach ($datastore in @(Get-VM $vm | Get-Datastore)) {
                foreach ($Network in @(Get-VM $vm | Get-NetworkAdapter)) {
                    $objGuest= "" | Select-Object State, Name,CPU, Memory, IPAddress, OSFullName, Cluster, Folder, UsedspaceGB, Datastore, Description, MacAddress, Path, NetworkName, NetworkAdapter
                    $objGuest.State= $vmguest.state
                    $objGuest.CPU = $vm.NumCPU
                    $objGuest.Memory = $vm.MemoryMB
                    $objGuest.Description= $vm.Notes
                    $objGuest.Folder=$vm.Folder
                    $objGuest.Name = $vm.Name
                    $objGuest.IPAddress = [string]::Join(',',$vmguest.IPAddress)
                    $objGuest.OSFullName = $vmguest.OSFullName
                    $objGuest.UsedSpaceGb = $vm.UsedSpaceGB
                    $objGuest.Cluster = $cluster.Name
                    $objGuest.Datastore = $datastore.Name
                    $objGuest.MacAddress = $Network.MacAddress
                    $objGuest.Path = $vm.Extensiondata.Config.Files.VmPathName
                    $objGuest.NetworkName = $Network.NetworkName
                    $objGuest.NetworkAdapter = $Network.Name
                    $AuditVM += $objGuest
                }
            }
        }
    }
}

$AuditVM | Export-Csv C:\temp\VDI_Audit.csv -noTypeInformation | Format-Table -AutoSize # Replace C:\temp\VDI_Audit.csv with your path