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
    Delete-Select-VM-Snapshots-with-PowerCLI.ps1

.DESCRIPTION
    Connects to vCenter and deletes selected VMs' snapshots based on a CSV list (VM plus vCenter).

.FUNCTIONALITY
    Deletes selected VM snapshots via PowerCLI.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#
.NAME
    Delete-Select-VM-Snapshots-with-PowerCLI.ps1
.SUMMARY
    User will create a CSV file with the VM’s they want to clean up
    along with that VM’s respective vCenter Server. The script will then
    connect to the vCenter server(s) and go through one-by-one deleting
    the specified VM’s snapshots.

    By leveraging a tool by Rob de Veij called RV tools, we can easily
    create a list of VM’s with old snapshots. It may take some effort
    to convert the CSV output from RVTools into something that is formatted
    for this script.

    For this example, we’ll pick two VM’s. Desktop1 and 2008r2 App Server.
    Both VM’s are managed by the same vCenter Server, so the CSV table would
    look like this in Excel.

        vCenter	    VM
        VC1	        Desktop1
        VC1	        2008r2 App Server

    It’s very important to include the vCenter and VM headers because these
    are called by the script. The reason I included the vCenter Server here
    is because my customer has multiple vCenters and instead of forcing them
    to log into each one, why not make it easy and connect to all of them.

    When you first launch the script, it will import the CSV file and ask the
    user for their vCenter Credentials. This assumes that the credentials are
    the same for each vCenter you wish to connect to.

    The script then looks at the vCenter column of the CSV and de-duplicates
    it, thus creating a list of what unique vCenters we need to connect to.

    Once connected to the vCenter Server(s), it starts going down the
    list of VM’s and deleting their snapshots one by one. We could delete many
    snapshots at the same time, but here we’re just doing one at a time in an
    abundance of caution to avoid generating too many IOPs on our storage.

    This script generates a log file to show us when we kicked off a
    remove-snapshots task, how many snapshots are associated with that VM, and
    when the task finished. The log also includes any output from the
    Remove-Snapshot command in case of an error.
.HISTORY
    2017-06-20  user10 Bradford, Creator
    2022-12-06  IT Admin, Editor
.RESOURCE
    URL: https://vmspot.com/delete-select-vm-snapshots-with-powercli/

#>

#VARIABLES
$logfile = "C:\temp\log.txt" #Script's log file location
$vms = Import-Csv "C:\temp\Snapshots.csv"
$creds = Get-Credential #Get the user's credentials for vCenter (assumes the user has the same user/pass for all vCenters)
$timestamp = Get-Date #Get the current date/time and place entry into log that a new session has started

Add-Content $logfile "#####################################################"
Add-Content $logfile "$timestamp New Session Started"

$vcenters = Connect-VIServer -Server "srvvcenterp.example.com" -Protocol https

foreach ($vcenter in $vcenters) #Log into each vCenter included in the CSV file (assumes the user has the same user/pass for all vCenters)
    {
        $timestamp = Get-Date #Get the current date/time and place entry into log that the script is connecting to each vCenter
        $message = "$timestamp Connecting to $vcenter"
        Write-Host $message
        Add-Content $logfile  $message
        Connect-VIServer -Server "srvvcenterp.example.com" -Protocol https -Credential $creds
        Write-Host `n
    }

foreach ($vm in $vms) #Remove snapshots for each VM in the CSV
    {
        $vm = Get-VM #$vm.VM #Load the virtual machine object
        $snapshotcount = $vm | Get-Snapshot | measure #Get the number of snapshots for the VM
        $snapshotcount = $snapshotcount.Count #This line makes it easier to insert the number of snapshots into the log file
        $timestamp = Get-Date #Get the current date/time and place entry into log that the script is going to remove x number of shapshots for the VM
        $message = "$timestamp Removing $snapshotcount Snapshot(s) for VM $vm"
        Write-Host $message
        Add-Content $logfile  $message
        $vm | Get-Snapshot | Remove-Snapshot -confirm:$false | Out-File $logfile -Append #Removes the VM's snapshot(s) and writes any output to the log file
        $timestamp = Get-Date #Get the current date/time and place entry into log that the script has finished removing the VM's snapshot(s)
        Add-Content $logfile "$timestamp Snapshots removed for $vm"
    }
