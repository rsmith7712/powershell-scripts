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
    powerCLI_vCenterMgmt.ps1

.DESCRIPTION
    A reference of VMware PowerCLI commands for vCenter management (run from the PowerCLI shell).

.FUNCTIONALITY
    VMware PowerCLI vCenter management reference.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#

.GENERAL
The following PowerShell commands need to be run from
VMware's PowerCLI shell, and not a regular Ps shell.


.REQUIRED
You need to run the following commands from a PowerCLI shell.
To download PowerCLI, go to:
https://communities.vmware.com/community/vmtn/automationtools/powercli


.TO-DO
If using a static User account, change info below before running

.COMMANDS_COVERED_BELOW_IN_THE_FOLLOWING_ORDER
    - Connecting to vCenter
    - Starting VMs
    - Stopping VMs
    - Creating VMs
    - Getting Snapshots
    - Creating Snapshots
    - Consolidating Snapshots
    - Deleting Snapshots
    - Adding CPUs
    - Removing CPUs
    - Memory Modifications
    - ExtensionData
    - Network Info
    - Copying Files
    - SSH
    - Configuring Switch MTU


.REFERENCE
https://www.vmguru.com/series/powershell-friday/

#>


# +------------------------------------------------------+
# |        Load VMware modules if not loaded             |
# +------------------------------------------------------+
 
if ( !(Get-Module -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) ) {
    if (Test-Path -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\VMware, Inc.\VMware vSphere PowerCLI' ) {
        $Regkey = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\VMware, Inc.\VMware vSphere PowerCLI'
       
    } else {
        $Regkey = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\VMware, Inc.\VMware vSphere PowerCLI'
    }
    . (join-path -path (Get-ItemProperty  $Regkey).InstallPath -childpath 'Scripts\Initialize-PowerCLIEnvironment.ps1')
}
if ( !(Get-Module -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) ) {
    Write-Host "VMware modules not loaded/unable to load"
    Exit 99
}


###############################
#    CONNECTING TO vCENTER    #
###############################

#Request credentials otherwise it's passed in clear text
$credentials=Get-Credential -UserName administrator@vcenter.local -Message "Enter your vCenter password"
#$credentials = Get-Credential -UserName sysadmin@example.com -Message "Enter your vCenter password"

#Connect to a single vCenter server while passing CLEAR TEXT CREDENTIALS - Use for testing
# Connect-VIServer -Server domainvc1.example.com -User administrator@vsphere.local -Password ThisIsNotSecure

#Connect to a single vCenter server while requesting password, if using static User account
# Connect-VIServer -Server domainvc1.example.com -Credential $credentials

#Connect to multiple vCenter servers while requesting password, if using static User account
$vc = Connect-VIServer -Server domainvc1.example.com -Credential $credentials
Get-VM -Server $vc


######################
#    STARTING VMs    #
######################

#Start specific VM
# Get-VM -Name MyVM | Start-VM


######################
#    STOPPING VMs    #
######################

#Gracefully shutdown all VMs starting with an 'A'
# Shutdown-VMGuest -VM A*

#Check to see if a VM is running, and if so, Gracefully shut it down
# Get-VMGuest -VM A*  | Where-Object {$_.State -eq "Running"}  | Shutdown-VMGuest

#Force shutdown of all VMs starting with an 'A' (and list your resume on LinkedIn)
# Get-VMGuest -VM A*  | Where-Object {$_.State -eq "Running"}  | Shutdown-VMGuest -Confirm:$False

#Hard, Nasty Shutdown with Zero Grace and Possible Data Loss...
# Stop-VM -VM MyVM -Kill


######################
#    CREATING VMs    #
######################

#Create VM, specify Name & Resource Pool
# New-VM -Name 'VMname' -ResourcePool 'ResourcePool'

#Create VM, specify Name, Resource Pool, and Datastore
# New-VM -Name 'VMname' -ResourcePool 'ResourcePool' -Datastore 'Datastore'

#Create VM, specify Name, Resource Pool (with details), NetworkName, and Datastore 
# New-VM -Name 'VMname' -ResourcePool 'ResourcePool' -NumCpu 4 -MemoryMB 2048 -DiskMB 40960 -NetworkName 'production network' -Datastore 'Datastore'

#To clone a VM
# New-VM -Name 'VMname' -VM 'VMtoClone' -ResourcePool 'ResourcePool'

<#
"To import a virtual machine you will need to first get the 
folder name on a specific datastore and load that into a 
variable. You can then use that variable together with the 
new-vm cmdlet to import a virtual machine"
#>
# cd vmstores:\MYserver@443\Datacenter\Datastore\MYVirtualMachine\
# $vmxFile = Get-Item 'MyVirtualMachine.vmx'
# $vmhost = Get-VMHost -Name 'MyVMHost'
# New-VM -VMHost $vmhost -VMFilePath $vmxFile.DatastoreFullPath


###########################
#    GETTING SNAPSHOTS    #
###########################

#Get a list of VM's then pipe them to Get-Snapshot (exports without context)
# $snapshots = Get-VM -Server $vc | Get-Snapshot

#Get a list (table) that can be used
# Get-VM | Get-Snapshot | Select VM,Created,Name,SizeMB | FT

#Get all VMs where the snapshots are older than 7 days.
# Get-VM | Get-Snapshot | Where {$_.Created -lt (Get-Date).AddDays(-7)} | Select-Object VM, Name, Created, SizeMB | Export-CSV "C:\temp\vCenter_Snapshots_OlderThan7Days.csv"
# Get-VM | Get-Snapshot | Where {$_.Created -lt (Get-Date).AddDays(-7)} | Select-Object VM, Name, Created, SizeMB | Out-File "C:\temp\vCenter_Snapshots_OlderThan7Days.txt"


############################
#    CREATING SNAPSHOTS    #
############################

#Create new snapshot
# New-Snapshot -VM MyVM -Name BeforeUpdate

#Create new snapshot utilizing the pipeline
# Get-VM -Name MyVM | New-Snapshot -Name BeforePatch


#################################
#    CONSOLIDATING SNAPSHOTS    #
#################################

#Initiate consolidation for specific server
# Get-VM | Where-Object {$_.Extensiondata.Runtime.ConsolidationNeeded}

#Show list of VM's needing consolidation, and initiate process for all
# Get-VM | Where-Object {$_.Extensiondata.Runtime.ConsolidationNeeded} | foreach {$_.ExtensionData.ConsolidateVMDisks_Task()}


############################
#    DELETING SNAPSHOTS    #
############################

#Delete all snapshots for a specific VM
# Get-VM -Name MyVM | Get-Snapshot | Remove-Snapshot

#Delete specific snapshot on a particular server
# Get-VM -Name MyVM | Get-Snapshot -Name TheNameOfTheSnapshot | Remove-Snapshot

#Delete all snapshots older than 7-days
# Get-VM | Get-Snapshot | Where {$_.Created -lt (Get-Date).AddDays(-7)} | Remove-Snapshot


#####################
#    ADDING CPUs    #
#####################

#Get a VM and change the number of CPUs
# Get-VM -name MyVM | set-VM -NumCpu 2


#######################
#    REMOVING CPUs    #
#######################

#Reduce the number of CPUs a VM has
# Get-VM -name MyVM | set-VM -NumCpu 1


##############################
#    MEMORY MODIFICATIONS    #
##############################

#Query specific VM for details before any add
# Get-VM -Name MyVM

#Get a list of all VMs with their Name and Memory
# Get-VM -Name MyVM | FT Name, MemoryGB

#Adding memory to a specific VM
# Get-VM -Name MyVM | Set-VM -MemoryGB 2

#To reduce memory, VM must be powered down
# Get-VM -Name MyVM | Shutdown-VMGuest|Set-VM -MemoryGB 1


#######################
#    EXTENSIONDATA    #
#######################

#View specific VM ExtensionData (additional info usually hidden)
# (Get-VM -Name MyVM).ExtensionData

#Query to see if VMware Tools are running on a specific server
# (Get-VM -Name MyVM).ExtensionData.Guest.ToolsRunningStatus

#Query VM Uptime through ExtensionData
# [timespan]::fromseconds((Get-VM -Name MyVM).ExtensionData.Summary.QuickStats.UptimeSeconds)


######################
#    NETWORK INFO    #
######################

#Query specific VM for it's IP address
# (Get-VM -Name MyVM).Guest.IPAddress

#Query all VMs on a host for their associated IP addresses; Returns IPs only
# (Get-VM).Guest.IPAddress

#Query specific VM for IP address in a usable format
# Get-VM -Name MyVM | Select Name, @{N="IP";E={@($_.Guest.IPAddress)}}

#Query all VMs for associated IPs
# Get-VM | Get-VMGuest | Format-Table VM, IPAddress


#######################
#    COPYING FILES    #
#######################

#Copy single file to a VM using regular PowerShell
# Copy-Item -Path '\\target\share$\test.txt' -Destination 'c:\temp\'

#Copy single file TO a VM using the vSphere API and Copy-VMGuestFile cmdlet
# Copy-VMGuestFile -Source c:\test.txt -Destination c:\temp\ -VM myVM -LocalToGuest -HostUser root -HostPassword pass1 -GuestUser user -GuestPassword pass2

#Copy single file FROM a remote VM to your local system
# Copy-VMGuestFile -Source c:\test.txt -Destination c:\temp\ -VM myVM -GuestToLocal -HostUser root -HostPassword pass1 -GuestUser

#Copy files from a source system TO multiple VMs
# $vm = Get-VM -Name VM*  | Copy-VMGuestFile -Source c:\tnsnames.ora -Destination c:\MyFolder -VM $vm -LocalToGuest -GuestUser -GuestPassword pass2


#############
#    SSH    #
#############

#Enabling SSH on all hosts in a vCenter
# Get-VMHost | Foreach {Start-VMHostService -HostService ($_ | Get-VMHostService | Where { $_.Key -eq "TSM-SSH"} )}

#To filter which hosts SSH is enabled on, specify them on the Get-VMHost
# Get-VMHost -Name MyHosts*| Foreach {Start-VMHostService -HostService ($_ | Get-VMHostService | Where { $_.Key -eq "TSM-SSH"} )}

#Query which hosts have SSH enabled
# Get-VMHost | Get-VMHostService | Where { $_.Key -eq "TSM-SSH" } |select VMHost, Label, Running

#Disable SSH on all VMs on a host
# Get-VMHost | Foreach {Stop-VMHostService -HostService ($_ | Get-VMHostService | Where { $_.Key -eq "TSM-SSH"} )}


################################
#    CONFIGURING SWITCH MTU    #
################################

#Configure MTU on a standard vSwitch
# $vswitch = Get-VirtualSwitch -Name vSwitch0 -VMHost (Get-VMHost -Name esxi01.lab.local)
# Set-VirtualSwitch $vswitch -Mtu 9000

#Configure MTU on a distributed vSwitch
# Import-Module VMware.VimAutomation.Vds
# $vswitch = Get-VDSwitch -Name dvSwitch 
# Set-VDSwitch $vswitch -Mtu 9000

#Configure VMKernel PortGroups
# $vmkernel = Get-VMHostNetworkAdapter -Name vmk0 -VMHost (Get-VMHost -Name esxi01.lab.local)
# Set-VMHostNetworkAdapter -VirtualNic $vmkernel -Mtu 9000

