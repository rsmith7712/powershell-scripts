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
    Get-IQN-For-All-Managed-Hosts.ps1

.DESCRIPTION
    Retrieves the iSCSI IQNs of all ESXi hosts under vCenter and exports them to CSV (for the CMDB/DR records).

.FUNCTIONALITY
    Reports ESXi host IQNs to CSV.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#
.NAME
    Get-IQN-For-All-Managed-Hosts.ps1

.SUMMARY
    This script will retreive the IQNs of all ESXi hosts under your vCenter
    Server and will export this information in a table-like format to a CSV file.

.DESCRIPTION
    Because of an error in the past, I wanted to make sure that all IQNs were stored
    in our CMDB and available at times of disaster.

    I created a script for this, which will get the IQNs for all ESXi hosts under
    your vCenter server and export the information to a CSV file.

.PREREQUISITE
    You need VMware PowerCLI installed on your machine and an active
    connection to one or more vCenter servers.

.NOTES
    Rene Bos        Creator // 2013-05-24
    IT Admin   Modifier

.RESOURCE-URL
    https://snowvm.com

#>

#Connect to VMware vCenter Instance
Connect-VIServer -Server "srvvcenterp.example.com" -Protocol https

#Customizations
$CsvPath = "C:\Temp\Report-IQN-Export.csv"

#Variables
$ESXiHosts = Get-VMHost | Sort-Object
foreach ($ESXiHost in $ESXiHosts)
    {
        $h = Get-VMhost $ESXiHost.Name
        Write-Host "Getting IQN for $h"
        $hosdomainew = Get-View $h.id
        $storage = Get-View $hosdomainew.ConfigManager.StorageSystem
        $a = [PSCustomObject]@{
                Hostname = $h.Name
                IQN = $storage.StorageDeviceInfo.HostBusAdapter.iScsiName
            }
        $a | Export-CSV -Path $CsvPath -Append
    }
Write-Host "CSV exported to $CsvPath"
