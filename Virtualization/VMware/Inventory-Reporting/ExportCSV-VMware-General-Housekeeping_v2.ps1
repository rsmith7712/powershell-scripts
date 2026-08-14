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
    ExportCSV-VMware-General-Housekeeping_v2.ps1

.DESCRIPTION
    Performs a general vCenter/vSphere host health check (PowerCLI version, ESXi versions, datacenter inventory) and exports to CSV (v2).

.FUNCTIONALITY
    Reports a general VMware health check to CSV.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#
.TITLE
    ExportCSV-VMware-General-Housekeeping.ps1

.SUMMARY
    General health check of vCenter / vSphere hosts

.INTENT
Connect to vCenter environment
Address Invalid Certificate warning
Check PowerCLI version
Store in variable; Query VMware site for ESXi current version
Store in variable; Query VMware site for ESXi previous version
Store in variable; List connected Datacenter
Store in variable; List connected Host
Store in variable; List connected Datastore
Store in variable; List VM Snapshots (Sort by VM, Name, Created), Export to CSV

Create For loop to process:
    Compare Host

.URL - VMware Build numbers and version of ESXi / ESX (KB 2143832)
https://kb.vmware.com/s/article/2143832

#>

## Variables

#Connect to VMware vCenter Instance
Connect-VIServer -Server  "srvvcenterp.example.com" -Protocol https

#If Applicable, Set Invalid Certificate Action
Set-PowerCLIConfiguration -Scope AllUsers -ParticipateInCeip $false -InvalidCertificateAction Ignore

#Check PowerCLI Version
Get-PowerCLIVersion

#Query VMware site for ESXi current version


#Query VMware site for ESXi previous version (immediate previous rtm)


#List of all DATACENTER attached to vCenter
Get-Datacenter | Export-Csv C:\temp\Report-Vmware-DataCenter.csv -NoTypeInformation -UseCulture

#List of all VMware HOST connected to vCenter - Store list in variable
Get-VMHost | Export-Csv C:\temp\Report-Vmware-VMHost.csv -NoTypeInformation -UseCulture

#List of all DATASTORE connected to vCenter
Get-Datastore | Export-Csv C:\temp\Report-Vmware-Datastore.csv -NoTypeInformation -UseCulture

#List of all SNAPSHOTS within vCenter, Export to CSV
Get-VM | Get-Snapshot | Select-Object VM, Name, Created | Export-Csv C:\temp\Report-Vmware-CurrentSnaps.csv -NoTypeInformation -UseCulture

#Create BACKUP of VMware Host - (Create variable to reference host name)
Get-VMHostFirmware -VMHost * -BackupConfiguration -DestinationPath C:\Temp

#Across all connected Datacenter sites, Export list of associated host (name, build & version)
Get-Datacenter * | Get-Vmhost | `
    Select-Object Name, @{N = 'Full name'; E={$_. ExtensionData.Config.Product.FullName}} | `
    Export-Csv C:\temp\Report-Vmware-DC-host-n-build-info.csv -NoTypeInformation -UseCulture


#List VMs that Need Tools or Hardware Updated
# Get VMs and initialize counter
$vms = Get-Datacenter | Get-VM
$i=0

# Create table and add columns
$table = New-Object System.Data.DataTable "NeedsUpdated"
$col1 = New-Object System.Data.DataColumn "Name"
$col2 = New-Object System.Data.DataColumn "HardwareVersion"
$col3 = New-Object System.Data.DataColumn "ToolsVersion"
$col4 = New-Object System.Data.DataColumn "ToolsStatus"
$table.Columns.Add($col1)
$table.Columns.Add($col2)
$table.Columns.Add($col3)
$table.Columns.Add($col4)

# Check hardware and tools versions
foreach($vm in $vms){
    $vmview = $vm | Get-View
    if(($vmview.Guest.ToolsVersionStatus -notlike "*Current") -OR ($vm.HardwareVersion -notlike "*13*")){
    $row = $table.NewRow()
    $row.Name = $vm.Name
    $row.HardwareVersion = $vm.HardwareVersion
    $row.ToolsVersion = $vmview.Guest.ToolsVersion
    $row.ToolsStatus = $vmview.Guest.ToolsVersionStatus
    $table.Rows.Add($row)
    }
    $i++
}

# Format table and export to csv
$table | Format-Table -AutoSize
$table | Export-Csv C:\temp\Report-vCenter-General-Housekeeping.csv -noType
