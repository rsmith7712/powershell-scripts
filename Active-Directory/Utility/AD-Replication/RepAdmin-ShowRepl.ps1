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
    RepAdmin-ShowRepl.ps1

.DESCRIPTION
    Reports inbound replication status for a domain controller via repadmin /showrepl (CSV and errors-only).

.FUNCTIONALITY
    Reports DC replication status.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#
Repadmin triggers a request to pull inbound
replication information from a domain controller
named DC2012. The command /csv gives the output
in .csv format, and /Errorsonly shows only
connections with errors.


#>

#Get the replication info using Repadmin
repadmin /showrepl srv "DC=domain,DC=com" /csv

#Get the replication info using Repadmin Errors Only
repadmin /showrepl srv "DC=domain,DC=com" /csv /Errorsonly


<#
work with the output in PowerShell, you can pipe
the output to the ConvertFrom-Csv cmdlet to create
objects. Then you can format the information as
shown below.
#>

repadmin /showrepl srv "DC=domain,DC=com" /csv | ConvertFrom-Csv | ? { $_.'Number of Failures' -ne 0} | select 'Source DSA','Destination DSA','Last Failure Time'