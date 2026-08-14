# LEGAL
<# LICENSE
    MIT License, Copyright 2018 Richard Smith

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
    KickOff-Mailbox.ps1

.DESCRIPTION
    Applies a mailbox-quota script to a list of mailboxes using throttled background jobs.

.FUNCTIONALITY
    Bulk-applies mailbox quotas with job throttling.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>



$mboxes = Get-Content C:\temp\Mailbox.csv

$SB = {
    & "C:\temp\Set-MailboxQuota.ps1" -Mailbox """$args[0]""" -UseDatabaseDefaults 
}
$maxConcurrentJobs = 10 #Max. number of simultaneously running jobs
 
foreach($mbox in $mboxes) { #Where $Objects is a collection of objects to process. It may be a computers list, for example.
    $Check = $false #Variable to allow endless looping until the number of running jobs will be less than $maxConcurrentJobs.
    while ($Check -eq $false) {
        if ((Get-Job -State 'Running').Count -lt $maxConcurrentJobs) {
            Start-Job -ScriptBlock $SB -ArgumentList $mbox
            $Check = $true #To stop endless looping and proceed to the next object in the list.
        }
    }
}