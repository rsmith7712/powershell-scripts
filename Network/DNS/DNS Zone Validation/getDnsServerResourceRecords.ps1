# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the “Software”),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS
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
   - getDnsServerResourceRecords.ps1

.SYNOPSIS
    - 

.FUNCTIONALITY
    Prompts for Input, or Does It?

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

import-module DNSServer
$DNSReport = 
foreach($record in Get-DnsServerZone){
    $DNSInfo = Get-DnsServerResourceRecord $record.zoneName
    
    foreach($info in $DNSInfo){
        [pscustomobject]@{
            ZoneName   = $record.zoneName
            HostName   = $info.hostname
            TimeStamp  = $info.timestamp
            RecordType = $info.recordtype
            RecordData = if($info.RecordData.IPv4Address){
                             $info.RecordData.IPv4Address.IPAddressToString}
                         else{
                             try{$info.RecordData.NameServer.ToUpper()}catch{}
                         }
        }
    }
}
$DNSReport |
Export-Csv "DNSRecords.csv" -NoTypeInformation