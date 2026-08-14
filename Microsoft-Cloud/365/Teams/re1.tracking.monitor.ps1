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
    re1.tracking.monitor.ps1

.DESCRIPTION
    Exports monthly Exchange message-tracking (sent and received) for a set of monitored mailboxes to CSV.

.FUNCTIONALITY
    Exports per-user mail-tracking reports (monthly).

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

get-messagetrackinglog -ResultSize Unlimited -sender "user34@example.com" -EventID "RECEIVE" -start "10/1/2016 1:00AM" -end "11/1/2016 1:00AM" |select timestamp,sender,{$_.recipients},messagesubject,totalbytes | export-csv c:\Reports\MailflowMonitor\Reports\re1\monthly.user34.sent.tracking.10.1.2016.csv
get-messagetrackinglog -ResultSize Unlimited -Recipients:"user34@example.com" -EventID "RECEIVE" -start "10/1/2016 1:00AM" -end "11/1/2016 1:00AM" |select timestamp,sender,{$_.recipients},messagesubject,totalbytes | export-csv c:\Reports\MailflowMonitor\Reports\re1\monthly.user34.receive.tracking.10.1.2016.csv
get-messagetrackinglog -ResultSize Unlimited -sender "user35@example.com" -EventID "RECEIVE" -start "10/1/2016 1:00AM" -end "11/1/2016 1:00AM" |select timestamp,sender,{$_.recipients},messagesubject,totalbytes | export-csv c:\Reports\MailflowMonitor\Reports\re1\monthly.user35.sent.tracking.10.1.2016.csv
get-messagetrackinglog -ResultSize Unlimited -Recipients:"user35@example.com" -EventID "RECEIVE" -start "10/1/2016 1:00AM" -end "11/1/2016 1:00AM" |select timestamp,sender,{$_.recipients},messagesubject,totalbytes | export-csv c:\Reports\MailflowMonitor\Reports\re1\monthly.user35.receive.tracking.10.1.2016.csv
get-messagetrackinglog -ResultSize Unlimited -sender "user36@example.com" -EventID "RECEIVE" -start "10/1/2016 1:00AM" -end "11/1/2016 1:00AM" |select timestamp,sender,{$_.recipients},messagesubject,totalbytes | export-csv c:\Reports\MailflowMonitor\Reports\re1\monthly.user36.sent.tracking.10.1.2016.csv
get-messagetrackinglog -ResultSize Unlimited -Recipients:"user36@example.com" -EventID "RECEIVE" -start "10/1/2016 1:00AM" -end "11/1/2016 1:00AM" |select timestamp,sender,{$_.recipients},messagesubject,totalbytes | export-csv c:\Reports\MailflowMonitor\Reports\re1\monthly.user36.receive.tracking.10.1.2016.csv
get-messagetrackinglog -ResultSize Unlimited -sender "user37@example.com" -EventID "RECEIVE" -start "10/1/2016 1:00AM" -end "11/1/2016 1:00AM" |select timestamp,sender,{$_.recipients},messagesubject,totalbytes | export-csv c:\Reports\MailflowMonitor\Reports\re1\monthly.user37.sent.tracking.10.1.2016.csv
get-messagetrackinglog -ResultSize Unlimited -Recipients:"user37@example.com" -EventID "RECEIVE" -start "10/1/2016 1:00AM" -end "11/1/2016 1:00AM" |select timestamp,sender,{$_.recipients},messagesubject,totalbytes | export-csv c:\Reports\MailflowMonitor\Reports\re1\monthly.user37.receive.tracking.10.1.2016.csv
get-messagetrackinglog -ResultSize Unlimited -sender "user38@example.com" -EventID "RECEIVE" -start "10/1/2016 1:00AM" -end "11/1/2016 1:00AM" |select timestamp,sender,{$_.recipients},messagesubject,totalbytes | export-csv c:\Reports\MailflowMonitor\Reports\re1\monthly.user38.sent.tracking.10.1.2016.csv
get-messagetrackinglog -ResultSize Unlimited -Recipients:"user38@example.com" -EventID "RECEIVE" -start "10/1/2016 1:00AM" -end "11/1/2016 1:00AM" |select timestamp,sender,{$_.recipients},messagesubject,totalbytes | export-csv c:\Reports\MailflowMonitor\Reports\re1\monthly.user38.receive.tracking.10.1.2016.csv
get-messagetrackinglog -ResultSize Unlimited -sender "user39@example.com" -EventID "RECEIVE" -start "10/1/2016 1:00AM" -end "11/1/2016 1:00AM" |select timestamp,sender,{$_.recipients},messagesubject,totalbytes | export-csv c:\Reports\MailflowMonitor\Reports\re1\monthly.user39.sent.tracking.10.1.2016.csv
get-messagetrackinglog -ResultSize Unlimited -Recipients:"user39@example.com" -EventID "RECEIVE" -start "10/1/2016 1:00AM" -end "11/1/2016 1:00AM" |select timestamp,sender,{$_.recipients},messagesubject,totalbytes | export-csv c:\Reports\MailflowMonitor\Reports\re1\monthly.user39.receive.tracking.10.1.2016.csv
exit
