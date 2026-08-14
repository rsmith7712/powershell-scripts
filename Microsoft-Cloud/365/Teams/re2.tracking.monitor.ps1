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
    re2.tracking.monitor.ps1

.DESCRIPTION
    Exports daily Exchange message-tracking (sent and received) for a set of monitored mailboxes to CSV.

.FUNCTIONALITY
    Exports per-user mail-tracking reports (daily).

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

get-messagetrackinglog -ResultSize Unlimited -sender "user40@example.com" -EventID "RECEIVE" -start "11/22/2016 1:00AM" -end "11/23/2016 1:00AM" |select timestamp,sender,{$_.recipients},messagesubject,totalbytes | export-csv c:\Reports\MailflowMonitor\Reports\re2\daily.user40.sent.tracking.11.22.2016.csv
get-messagetrackinglog -ResultSize Unlimited -Recipients:"user40@example.com" -EventID "RECEIVE" -start "11/22/2016 1:00AM" -end "11/23/2016 1:00AM" |select timestamp,sender,{$_.recipients},messagesubject,totalbytes | export-csv c:\Reports\MailflowMonitor\Reports\re2\daily.user40.receive.tracking.11.22.2016.csv
get-messagetrackinglog -ResultSize Unlimited -sender "user41@example.com" -EventID "RECEIVE" -start "11/22/2016 1:00AM" -end "11/23/2016 1:00AM" |select timestamp,sender,{$_.recipients},messagesubject,totalbytes | export-csv c:\Reports\MailflowMonitor\Reports\re2\daily.user41.sent.tracking.11.22.2016.csv
get-messagetrackinglog -ResultSize Unlimited -Recipients:"user41@example.com" -EventID "RECEIVE" -start "11/22/2016 1:00AM" -end "11/23/2016 1:00AM" |select timestamp,sender,{$_.recipients},messagesubject,totalbytes | export-csv c:\Reports\MailflowMonitor\Reports\re2\daily.user41.receive.tracking.11.22.2016.csv
get-messagetrackinglog -ResultSize Unlimited -sender "user42@example.com" -EventID "RECEIVE" -start "11/22/2016 1:00AM" -end "11/23/2016 1:00AM" |select timestamp,sender,{$_.recipients},messagesubject,totalbytes | export-csv c:\Reports\MailflowMonitor\Reports\re2\daily.user42.sent.tracking.11.22.2016.csv
get-messagetrackinglog -ResultSize Unlimited -Recipients:"user42@example.com" -EventID "RECEIVE" -start "11/22/2016 1:00AM" -end "11/23/2016 1:00AM" |select timestamp,sender,{$_.recipients},messagesubject,totalbytes | export-csv c:\Reports\MailflowMonitor\Reports\re2\daily.user42.receive.tracking.11.22.2016.csv
get-messagetrackinglog -ResultSize Unlimited -sender "user43@example.com" -EventID "RECEIVE" -start "11/22/2016 1:00AM" -end "11/23/2016 1:00AM" |select timestamp,sender,{$_.recipients},messagesubject,totalbytes | export-csv c:\Reports\MailflowMonitor\Reports\re2\daily.user43.sent.tracking.11.22.2016.csv
get-messagetrackinglog -ResultSize Unlimited -Recipients:"user43@example.com" -EventID "RECEIVE" -start "11/22/2016 1:00AM" -end "11/23/2016 1:00AM" |select timestamp,sender,{$_.recipients},messagesubject,totalbytes | export-csv c:\Reports\MailflowMonitor\Reports\re2\daily.user43.receive.tracking.11.22.2016.csv
get-messagetrackinglog -ResultSize Unlimited -sender "user44@example.com" -EventID "RECEIVE" -start "11/22/2016 1:00AM" -end "11/23/2016 1:00AM" |select timestamp,sender,{$_.recipients},messagesubject,totalbytes | export-csv c:\Reports\MailflowMonitor\Reports\re2\daily.user44.sent.tracking.11.22.2016.csv
get-messagetrackinglog -ResultSize Unlimited -Recipients:"user44@example.com" -EventID "RECEIVE" -start "11/22/2016 1:00AM" -end "11/23/2016 1:00AM" |select timestamp,sender,{$_.recipients},messagesubject,totalbytes | export-csv c:\Reports\MailflowMonitor\Reports\re2\daily.user44.receive.tracking.11.22.2016.csv
get-messagetrackinglog -ResultSize Unlimited -sender "user39@example.com" -EventID "RECEIVE" -start "11/22/2016 1:00AM" -end "11/23/2016 1:00AM" |select timestamp,sender,{$_.recipients},messagesubject,totalbytes | export-csv c:\Reports\MailflowMonitor\Reports\re2\daily.user39.sent.tracking.11.22.2016.csv
get-messagetrackinglog -ResultSize Unlimited -Recipients:"user39@example.com" -EventID "RECEIVE" -start "11/22/2016 1:00AM" -end "11/23/2016 1:00AM" |select timestamp,sender,{$_.recipients},messagesubject,totalbytes | export-csv c:\Reports\MailflowMonitor\Reports\re2\daily.user39.receive.tracking.11.22.2016.csv
get-messagetrackinglog -ResultSize Unlimited -sender "user37@example.com" -EventID "RECEIVE" -start "11/22/2016 1:00AM" -end "11/23/2016 1:00AM" |select timestamp,sender,{$_.recipients},messagesubject,totalbytes | export-csv c:\Reports\MailflowMonitor\Reports\re2\daily.user37.sent.tracking.11.22.2016.csv
get-messagetrackinglog -ResultSize Unlimited -Recipients:"user37@example.com" -EventID "RECEIVE" -start "11/22/2016 1:00AM" -end "11/23/2016 1:00AM" |select timestamp,sender,{$_.recipients},messagesubject,totalbytes | export-csv c:\Reports\MailflowMonitor\Reports\re2\daily.user37.receive.tracking.11.22.2016.csv
exit
