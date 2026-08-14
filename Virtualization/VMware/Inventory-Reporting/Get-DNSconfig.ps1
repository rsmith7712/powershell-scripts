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
    Get-DNSconfig.ps1

.DESCRIPTION
    Audits the DNS server configuration of DMZ virtual machines, logging results to CSV.

.FUNCTIONALITY
    Audits VM DNS configuration.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>



# ----------------------------------------------------------------------------------------------
# Logging
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\DMZ_DNS_Audit_$stamp.csv"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "VM Hostname, DNS Servers"

function Append-Log($message)
{
	Add-Content $Script:LogFile "$message"
}

Connect-VIServer -Server DomainVC1

$ResourcePools=@("DMZ_Tier1","DMZ_Tier2")
$Computers = $NULL

ForEach($Pool in $ResourcePools)
{
    $VMs = Get-ResourcePool $Pool | Get-VM | Select-Object Name
    $Computers += $VMs.name
}

ForEach($Computer in $Computers)
{
    $VM = Get-VM -Name $Computer
    $DNS = [string]::Join(',',($vm.ExtensionData.Guest.IpStack.DnsConfig.IpAddress))
    Append-Log """$Computer"",""$DNS"""
}