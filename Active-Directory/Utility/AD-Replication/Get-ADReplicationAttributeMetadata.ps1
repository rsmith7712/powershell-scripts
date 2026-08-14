# LEGAL
<# LICENSE
    MIT License, Copyright 2023 Richard Smith

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
    Get-ADReplicationAttributeMetadata.ps1

.DESCRIPTION
    Queries Active Directory replication attribute metadata for an object to show what, when and where it was modified.

.FUNCTIONALITY
    Reports AD replication attribute metadata.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#
This cmdlet queries replication metadata for an
object from a specified directory server. The
output of this command shows the what, when, and
where for a particular object's modification within
the boundary of your AD, but it doesn't say who
modified the object. If auditing is enabled, it
helps you identify the modifier details.

The command displays the metadata of a deleted
record from Windows 8 from the zone test.local.
This object was deleted on 09/29/2019 from the
server DC2012.

If you want to know who deleted this record,
check the security event 4662 from the security
log. Note that you should enable DNS auditing
to get the events under security.
#>

Get-ADReplicationAttributeMetadata "DC=Win8,DC=test.local,CN=MicrosoftDNS,DC=DomainDnsZones,DC=test,DC=local" -Server DC2012 -IncludeDeletedObjects -ShowAllLinkedValues | Where-Object { $_.attributename -eq "dnsTombstoned" }