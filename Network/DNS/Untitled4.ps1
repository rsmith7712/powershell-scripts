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
    Untitled4.ps1

.DESCRIPTION
    This script is designed to be used as part of an audit of Active Directory
    Computer Accounts that have been inactive for longer than 90-days.  The
    script will query Active Directory for computer accounts that have not had
    their password set in the last 90-days and export the results to a CSV file.

.FUNCTIONALITY


.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>

$results = Get-DnsServerZone | % {
    $zone = $_.zonename
    Get-DnsServerResourceRecord $zone | select @{n='ZoneName';e={$zone}}, HostName, timestamp, RecordType, @{n='RecordData';e={if ($_.RecordData.IPv4Address.IPAddressToString) {$_.RecordData.IPv4Address.IPAddressToString} else {$_.RecordData.NameServer.ToUpper()}}}
}

$results | Export-Csv -NoTypeInformation C:\temp\DNSRecords.csv -Append