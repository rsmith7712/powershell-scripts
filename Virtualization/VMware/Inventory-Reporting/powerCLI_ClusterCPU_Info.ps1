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
    powerCLI_ClusterCPU_Info.ps1

.DESCRIPTION
    Connects to a list of vCenter servers and reports CPU information per cluster host.

.FUNCTIONALITY
    Reports cluster CPU information.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Connect-VIServer -Server (Get-Content C:\temp\vCenterList.txt) > $null


$report = Foreach($vc in $global:DefaulDomainServers){

    foreach($dc in Get-Datacenter -Server $vc){

        Get-Cluster -Location $dc -Server $vc -PipelineVariable cluster |

        Get-VMHost |

        Select @{N='VC';E={$vc.Name}},

            @{N='Datacenter';E={$dc.Name}},

            @{N='Cluster';E={$cluster.Name}},

            @{N='#ESXi';E={$cluster.ExtensionData.Host.Count}},

            Name,

            @{N='ESXi version';E={"$($_.Version) $($_.Build)"}},

            @{N='ESXi HW';E={"$($_.ExtensionData.Hardware.SystemInfo.Vendor) $($_.ExtensionData.Hardware.SystemInfo.Model)"}},

            @{N='ESXi CPU';E={$_.ProcessorType}}

    }

}

$report | Export-Csv C:\temp\vCenterClusterInfo.csv