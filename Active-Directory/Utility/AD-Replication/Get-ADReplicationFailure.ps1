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
    Get-ADReplicationFailure.ps1

.DESCRIPTION
    Reports failed Active Directory replication details (partner, failure time, count) for a target server.

.FUNCTIONALITY
    Reports AD replication failures.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#
This queries the failed replication details for a
designated server based on the input target and scope.

The first figure shows that there currently is no
replication issue from ADC2012 to DC2012, but the
connection failed on 09/25/2019 at 12:01 AM. Yet note
it is not the most recent failure time. Any number of
retry attempts might have happened from the time of
failure until the replication succeeded. The failed
retries are stored in the FailureCount property, but
only if the connection is still in a failed state;
otherwise the value is 0.

#>


Get-ADReplicationFailure -Target srv | select Server,Partner,FirstFailureTime,FailureCount,FailureType