# LEGAL
<# LICENSE
    MIT License, Copyright 2017 Richard Smith

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
    SERVER.ps1

.SYNOPSIS
 Replicate a phrase for each time "Server" is said in every line.
 
.DESCRIPTION
 Replicates the "infrastructure's hellish way of torture by making the intern say a specific phrase" phrase for each time "Server" is listed.

.NOTES
 Version:           1.0
 Author:            Zachary Lundgren
 Creation Date:     11/2/2017
 Purpose/Change:    Change Default Gateway & Add Subnets

.FUNCTIONALITY
    Replicates the "infrastructure's hellish way of torture by making the intern say a specific phrase" phrase for each time "Server" is listed.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

function Send_Email() {
    $smtp = "smtpi.example.com"
    $to = "sysadmins@example.com"
    #$cc = 
    $from = "Zachary Lundgren <zlundgren@example.com>"
    $subject = "Server"
    $body = "Thats a nice rack."  
    send-MailMessage -SmtpServer $smtp -To $to -From $from -Subject $subject -Body $body -BodyAsHtml
}

#Imported text document.
$servers = import-csv -Path 'C:\Users\Dreshkin\Desktop\PShell Testing\Servers.txt'

#For each time it says "server", email the sysadmins the phrase.
foreach ($server in $servers){
    Send_Email
}




