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
    Get-VMware-Snapshot-Info.ps1

.DESCRIPTION
    Connects to vCenter and reports all virtual-machine snapshots to the console (removal command commented out).

.FUNCTIONALITY
    Reports all VM snapshots.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#
.Name
- Get-VMware-Snapshot-Info.ps1

Script:
- Connect to VMware vCenter
- Query for all VM snapshots
- Display results on console
- Comment out removal command (must be run manually)

#>

# Connect to VMware vCenter
Connect-VIServer -Server "srvvcenterp.example.com" -Protocol https

# Query for all VM snapshots; Display results on console
Get-VM | Get-Snapshot | Select-Object VM, Name, Created

# Query for all VM snapshots; Export results to Csv
#Get-VM | Get-Snapshot | Select-Object VM, Name, Created | Export-Csv C:\temp\VmwareGeneralHousekeeping-CurrentSnaps.csv -NoTypeInformation -UseCulture

# Remove All Snapshots -- May be needed if process generates 10+ snaps in vCenter at which point the GUI no longer allows removal
#Get-VM | Get-Snapshot | Remove-Snapshot -RunAsync