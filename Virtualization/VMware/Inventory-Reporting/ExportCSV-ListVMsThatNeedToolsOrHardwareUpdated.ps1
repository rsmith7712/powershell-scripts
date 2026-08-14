<#
.NAME
    ExportCSV-ListVMsThatNeedToolsOrHardwareUpdated.ps1

.SUMMARY
    List VMs that Need Tools or Hardware Updated

.PURPOSE
    This PowerShell script will help you easily determine what VM
    hardware version each of your VMs are currently running. Updating
    your VM hardware compatibility version can offer you benefits
    like supporting new CPU architectures, helping you squeeze every
    last bit of performance out of your VMs.

    This script will allow you to quickly determine which VMs need
    be addressed in a large environment and help you triage them
    accordingly.

.NOTE
    Change the HardwareVersion number above to whatever version you
    consider acceptable in your environment. The statement could
    also be modified to report anything lower than a specific
    version if you have a minimum that is acceptable outside the
    current version.

.AUTHOR
    Creator:    MattS
    Updated:    ITAdmin

.AUTHOR-URL
    https://github.com/mstewgt

.URL - Initial Source
    https://www.jackofalladmins.com/admin%20adventures/vms-need-tools-updated/
#>

# Import PowerCLI module, Ignore Certificate Errors, and connect to VSphere servers
Import-Module VMware.PowerCLI
#Set-PowerCLIConfiguration -Scope AllUsers -ParticipateInCeip $false -InvalidCertificateAction $false
Connect-VIServer -Server "srvvcenterp.example.com" -Protocol https

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
$csv = $table | Export-Csv C:\temp\Report-ListVMsThatNeedToolsOrHardwareUpdated.csv -noType
