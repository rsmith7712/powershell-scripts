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
    powerCLI_Report_VirtualMachine.ps1

.DESCRIPTION
    Connects to vCenter and produces a virtual-machine report (farm login via a credentials list).

.FUNCTIONALITY
    Reports vCenter virtual machines.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#Report_VirtualMachine.ps1

#Initialize PowerCLI
add-pssnapin VMware.VimAutomation.Core

# Farm Login
$vCUser="administrator@vsphere.local"
$vCPass="xxxx"

# LIST OF FARM
#$vCenterIP = "x.x.x.x"
$vCenterIP = Get-Content "C:\temp\vCenterList.txt"

foreach ($IPAddress in $vCenterIP){
    # Connessione a vCenter
    Connect-VIServer $IPAddress -User $vCUser -Password $vCPass -port 443
}

#Variables
$Date = get-date
$Datefile = ( get-date ).ToString(‘yyyy-MM-dd-hhmmss’)
$ErrorActionPreference = "SilentlyContinue"
# Variable to change
$CreateCSV= "yes"
$GridView = "no"
$HTML = "yes"
$DisplayHTMLOnScreen = "no"
$EmailHTML = "yes"
$SendEmail = "yes"
$FileHTML = New-Item -type file "C:\temp\VMWARE_REPORT_$datefile.html"
$FileCSV = New-Item -type file "C:\temp\VMWARE_REPORT_$datefile.csv"

#Text to the HTML file
Function Create-HTMLTable
{
param([array]$Array)
$arrHTML = $Array | ConvertTo-Html
$arrHTML[-1] = $arrHTML[-1].ToString().Replace(‘</body></html>’,"")
Return $arrHTML[5..2000]
}

$output = @()
$output += ‘<html><head></head><body>’
$output += 
‘<style>table{border-style:solid;border-width:1px;font-size:8pt;background-color:#7ab0f9;width:100%;}th{text-align:left;}td{background-color:#fff;width:20%;border-style:so
lid;border-width:1px;}body{font-family:verdana;font-size:12pt;}h1{font-size:12pt;}h2{font-size:10pt;}</style>’
$output += ‘<H1>[2018 - Report Monthly Virtual Machine</H1>’
$output += ‘<H2>Date and time</H2>’,$date

Write-Host "Gathering VM statistics"

$report = @()

foreach($vm in Get-View -ViewType Virtualmachine){
    $vms = "" | Select-Object VMName, Hostname, IPAddress, OS, Boottime, VMState, TotalCPU, CPUreservation, TotalMemory, MemoryUsage, MemoryReservation, TotalNics, ToolsStatus, ToolsVersion, HardwareVersion, TimeSync, CBT, Portgroup, VMHost, ProvisionedSpaceGB, UsedSpaceGB, Datastore, Notes, FaultTolerance, SnapshotName, SnapshotDate, SnapshotSizeGB, NB_LAST_BACKUP, Owner
    $vms.VMName = $vm.Name
    $vms.VMState = $vm.summary.runtime.powerState
    $vms.Boottime = $vm.Runtime.BootTime
    $vms.TotalNics = $vm.summary.config.numEthernetCards
    $vms.Portgroup = Get-View -Id $vm.Network -Property Name | select -ExpandProperty Name
    $vms.OS = $vm.Config.GuestFullName 
    $vms.Hostname = $vm.guest.hostname
    $vms.IPAddress = $vm.guest.ipAddress
    $vms.VMHost = Get-View -Id $vm.Runtime.Host -property Name | select -ExpandProperty Name
    $vms.ProvisionedSpaceGB = [math]::Round(($vm.Summary.Storage.Committed + $vm.Summary.Storage.UnCommitted)/1GB,2)
    $vms.UsedSpaceGB = [math]::Round($vm.Summary.Storage.Committed/1GB,2)
    $vms.MemoryReservation = $vm.resourceconfig.memoryallocation.reservation
    $vms.CPUreservation = $vm.resourceconfig.cpuallocation.reservation        
    $vms.TotalCPU = $vm.summary.config.numcpu
    $vms.TotalMemory = $vm.summary.config.memorysizemb
    $vms.MemoryUsage = $vm.summary.quickStats.guestMemoryUsage    
    $vms.ToolsStatus = $vm.guest.toolsstatus
    $vms.ToolsVersion = $vm.config.tools.toolsversion
    $vms.TimeSync = $vm.Config.Tools.SyncTimeWithHost
    $vms.HardwareVersion = $vm.config.Version
    $vms.MemoryReservation = $vm.resourceconfig.memoryallocation.reservation
    $vms.Datastore = $vm.Config.DatastoreUrl[0].Name
    $vms.CBT = $vm.Config.ChangeTrackingEnabled  
    $vms.Notes = $vm.Config.Annotation
    $vms.FaultTolerance = $vm.Runtime.FaultToleranceState
    $vms.SnapshotName = &{$script:snaps = Get-Snapshot -VM $vm.Name; $script:snaps.Name -join ','}
    $vms.SnapshotDate = $script:snaps.Created -join ','
    $vms.SnapshotSizeGB = $script:snaps.SizeGB -join ','
    $vms.Owner = (Get-TagAssignment -Category Owner -Entity $vm.Name).Tag.Name
    $vms.NB_LAST_BACKUP = Get-VM -Name $vm.Name | select -ExpandProperty Customfields | where{$_.Key -eq 'NB_LAST_BACKUP'} | select -ExpandProperty Value
    $Report += $vms

}

#Output
if ($GridView -eq "yes") {
$report | Out-GridView }

if ($CreateCSV -eq "yes") {
$report | Export-Csv $FileCSV -NoTypeInformation }

if ($HTML -eq "yes") {
$output += ‘<p>’
$output += ‘<H2>Report Virtual Machine</H2>’
$output += ‘<p>’
$output += Create-HTMLTable $report
$output += ‘</p>’
$output += ‘</body></html>’
$output | Out-File $FileHTML }

if ($DisplayHTMLOnScreen -eq "yes") {
ii $FileHTML}


#file CSV

$filename = "C:\temp\VMWARE_REPORT_$datefile.csv"
$smtpServer = “smtpi.example.com”
$msg = new-object Net.Mail.MailMessage
$att = new-object Net.Mail.Attachment($filename)
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$msg.From = “PowerCLI@example.com”
$msg.To.Add(”admin2@example.com”)
$msg.Subject = “Monthly Report - / VMware Virtual Machine CSV - $Date”
$msg.Body = "TEXT"
$msg.Attachments.Add($att)
$smtp.Send($msg)

#file HTML

$filename = "C:\temp\VMWARE_REPORT_$datefile.html"
$smtpServer = “smtpi.example.com”
$msg = new-object Net.Mail.MailMessage
$att = new-object Net.Mail.Attachment($filename)
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$msg.From = “PowerCLI@example.com”
$msg.To.Add(”admin2@example.com”)
$msg.Subject = “Monthly Report - / VMware Virtual Machine HTML - $Date”
$msg.Body = "TEXT"
$msg.Attachments.Add($att)
$smtp.Send($msg)


#Disconnect session from VC
Disconnect-VIserver -Confirm:$false