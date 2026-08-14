<#
########## ########## ########## ##########
########## Generate-Monster-Report ########
########## ########## ########## ##########

.NAME
    Generate-Monster-Report-For-All-Virtual-Machines.ps1

.AUTHOR
    LucD

.EDITED
    IT Admin

.URL-RESOURCE
https://communities.vmware.com/t5/VMware-PowerCLI-Discussions/List-of-al-VMs-with-all-fields/td-p/447777

#>

################################################ ################################################

<#
########## ########## ########## ##########
########## Send-EmailWithSendGrid #########
########## ########## ########## ##########
.Name
    Send-EmailWithSendGrid.ps1

.SUMMARY
    This function sends an email using SendGrid APIs

.DESCRIPTION
    This function sends an email using SendGrid REST API.

.EXAMPLE
    #Send-EMailWithSendGrid -from "email@domain" -to "email@domain" -ApiKey "MY_SENDGRID_API_KEY" -Body "Test 1..2..3!" -Subject "Sendgrid Test"
    #Send-EmailWithSendGrid -from $from -to $to -ApiKey $APIKEY -Body $Body -Subject $Subject
    #Send-EmailWithSendGrid @MailParams

.NOTES
    Author Paolo Frigo,  https://www.scriptinglibrary.com
    #SendGrid API Key: ZM-VMware-Monster-Report
    #SendGrid API Key: <apikey>

#>
################################################ ################################################

########## ########## ########## ##########
########## ####  VARIABLES  #### ##########
########## ########## ########## ##########


########## ########## ########## ##########
########## ####  FUNCTIONS  #### ##########
########## ########## ########## ##########
Function Send-EmailWithSendGrid {
    Param
   (
       [Parameter(Mandatory=$true)]
       [string] $From,

       [Parameter(Mandatory=$true)]
       [String] $To,

       [Parameter(Mandatory=$true)]
       [string] $ApiKey,

       [Parameter(Mandatory=$true)]
       [string] $Subject,

       [Parameter(Mandatory=$true)]
       [string] $Body
   )
   $headers = @{}
   $headers.Add("Authorization","Bearer $apiKey")
   $headers.Add("Content-Type", "application/json")

   $jsonRequest = [ordered]@{
                           personalizations= @(@{to = @(@{email =  "$To"})
                               subject = "$SubJect" })
                               from = @{email = "$From"}
                               content = @( @{ type = "text/plain"
                                           value = "$Body" }
                               )} | ConvertTo-Json -Depth 10
   Invoke-RestMethod   -Uri "https://api.sendgrid.com/v3/mail/send" -Method Post -Headers $headers -Body $jsonRequest
}

# $From = "email@address"
# $To = "email@address"
# $APIKEY = "MY_API_KEY"
# $Subject = "TEST"
# $Body ="SENDGRID 123"

$MailParams = @{
    From = "admin@example.com"
    To = "admin@example.com"
    APIKEY = "<apikey>"
    Subject = "SendGrid - Monster Report for All Virtual Machines"
    Body = $report
  }

########## ########## ########## ##########
########## ####    MAIN     #### ##########
########## ########## ########## ##########

# Import PowerCLI module
# NOTE: (VSCode) Exception: VMware.ImageBuilder module is not currently supported on the Core edition of PowerShell
# NOTE: (VSCode) Expected Exception
Import-Module VMware.PowerCLI

#Connect to VMware vCenter Instance
Connect-VIServer -Server  "srvvcenterp.example.com" -Protocol https

#If Applicable, Set Invalid Certificate Action - Enable If Environment Requires It
#Set-PowerCLIConfiguration -Scope AllUsers -ParticipateInCeip $false -InvalidCertificateAction Ignore

#Check PowerCLI Version - Enable for Troubleshooting
#Get-Module

#Gathering VM settings
Write-Host "Gathering VM statistics"

#Generate Monster Report For All Virtual Machines
$report = @()
foreach($vm in Get-View -ViewType Virtualmachine){
    $vms = "" | Select-Object VMName, Hostname, IPAddress, OS, Boottime, VMState, TotalCPU, CPUAffinity,
        CPUHotAdd, CPUShare, CPUlimit, OverallCpuUsage, CPUreservation, TotalMemory, MemoryShare, MemoryUsage,
        MemoryHotAdd, MemoryLimit, MemoryReservation, Swapped, Ballooned, Compressed, TotalNics, ToolsStatus,
        ToolsVersion, HardwareVersion, TimeSync, CBT, Portgroup, VMHost, ProvisionedSpaceGB, UsedSpaceGB, Datastore,
        FaultTolerance, SnapshotName, SnapshotDate, SnapshotSizeGB, Tags, NB_last_backup, Notes

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
    $vms.Portgroup = Get-View -Id $vm.Network -Property Name | Select-Object -ExpandProperty Name
    $vms.VMHost = Get-View -Id $vm.Runtime.Host -property Name | Select-Object -ExpandProperty Name
    $vms.ProvisionedSpaceGB = [math]::Round($vm.Summary.Storage.UnCommitted/1GB,2)
    $vms.UsedSpaceGB = [math]::Round($vm.Summary.Storage.Committed/1GB,2)
    $vms.Datastore = $vm.Config.DatastoreUrl[0].Name
    $vms.Notes = $vm.Config.Annotation
    $vms.FaultTolerance = $vm.Runtime.FaultToleranceState
    $vms.SnapshotName = &{$script:snaps = Get-Snapshot -VM $vm.Name; $script:snaps.Name -join ','}
    $vms.SnapshotDate = $script:snaps.Created -join ','
    $vms.SnapshotSizeGB = $script:snaps.SizeGB -join ','
    $vms.Tags = (Get-TagAssignment -Entity $vm.Name).Tag.Name -join ','
    $vms.NB_last_backup =  Get-VM -Name $vm.Name | Select-Object -ExpandProperty Customfields | Where-Object {$_.Key -eq 'NB Last Backup'} | Select-Object -ExpandProperty Value
    $Report += $vms
}

#Output to Email
Send-MailMessage -From 'Report Generator <admin@example.com>' -To 'IT Admin <admin@example.com>' -Subject 'Internal Monster Report for All Virtual Machines' `
-BodyAsHtml -Body ($report | ConvertTo-Html | Out-String) -Priority High -DeliveryNotificationOption OnSuccess, OnFailure -SmtpServer 'smtp-relay.example.com'


Send-EmailWithSendGrid @MailParams

#Output to Csv
if ($GridView -eq "yes") {$report | Out-GridView }
if ($CreateCSV -eq "yes") {$report | Export-Csv "C:\Temp\Monster-Report-For-All-Virtual-Machines.csv" -NoTypeInformation -NoClobber}
#if ($CreateCSV -eq "yes") {$report | Export-Csv $FileCSV -NoTypeInformation }
