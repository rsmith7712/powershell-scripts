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
    powerCLI_Test.ps1

.DESCRIPTION
    Test/scratch PowerCLI script for connecting to vCenter and exporting VM and host information.

.FUNCTIONALITY
    PowerCLI test/scratch script.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#Get-VM | Select Name,VMHost | Export-Csv -Path c:\temp\VMsAndHostsInfo.csv -NoTypeInformation -UseCulture

#Initialize PowerCLI
#add-pssnapin VMware.VimAutomation.Core

# Farm Login
$vCUser="sysadmin@example.com"
$vCPass="<password>"

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
$FileCSV = New-Item -type file "C:\temp\VMWARE_VMsAndHostsInfo_$datefile.csv"

Write-Host "Gathering VM statistics"

$report = @()

foreach($vm in Get-View -ViewType Virtualmachine){
    $vms = "" | Select-Object VMName, Hostname, VMHost
    $vms.VMName = $vm.Name
    $vms.Hostname = $vm.guest.hostname
    $vms.VMHost = Get-View -Id $vm.Runtime.Host -property Name | select -ExpandProperty Name   
    $vms.TotalCPU = $vm.summary.config.numcpu
    $Report += $vms

}

#Output
if ($GridView -eq "yes") {
$report | Out-GridView }

if ($CreateCSV -eq "yes") {
$report | Export-Csv $FileCSV -NoTypeInformation }