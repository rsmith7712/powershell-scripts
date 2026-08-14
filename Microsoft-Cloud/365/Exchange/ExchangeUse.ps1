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
    ExchangeUse.ps1

.DESCRIPTION
    Loads the Exchange management snap-in and summarizes message-tracking data (send/receive counts and data volume) for a date range from the transport/hub servers.

.FUNCTIONALITY
    Reports Exchange mail-flow volume from message-tracking logs.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

    $Localhost = $env:COMPUTERNAME
    #Load Exchange PS Snapin
    If ((Get-PSSnapin | Where-Object {$_.Name -eq "Microsoft.Exchange.Management.PowerShell.E2010"} ).name -eq 'Microsoft.Exchange.Management.PowerShell.E2010')
    {
    Write-Host "Exchange Snapin is already loaded...."
    }

    else
    {
    Write-Host "Loading Exchange Snapin Please Wait...."; Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
    }
    Write-Host "running..."

    $hubs = Get-TransportServer

    # Get the start date for the tracking log search
    $Start = (Get-Date -Hour 00 -Minute 00 -Second 00).AddDays(-15)

    # Get the end date for the tracking log search
    $End = (Get-Date -Hour 23 -Minute 59 -Second 59).AddDays(-15)

    $Datum = $Start.ToShortDateString()

    $receive = $hubs | get-messagetrackinglog -Start $Start -End $End -EventID "RECEIVE" -ResultSize Unlimited | select Sender,RecipientCount,TotalBytes,Recipients
    $send = $hubs | get-messagetrackinglog -Start $Start -End $End -EventID "SEND" -ResultSize Unlimited | select Sender,RecipientCount,TotalBytes
    $mreceive = $receive | Measure-Object TotalBytes -maximum -minimum -average -sum
    $msend = $send | Measure-Object TotalBytes -maximum -minimum -average -sum

    $anzahl = $mreceive.count + $msend.count
    $volumen = ($mreceive.sum + $msend.sum) / (1024 * 1024)

    $volumen = "{0:N2}" -f $volumen + " MB"

    $msendmb = $msend.sum / (1024 * 1024)
    $vsend = "{0:N2}" -f $msendmb + " MB"
    $bigsend = $msend.maximum / (1024 * 1024)
    $avsend = $msend.average / 1024

    $bigsendmb = "{0:N2}" -f $bigsend + " MB"
    $avsendkb = "{0:N2}" -f $avsend + " KB"

    $mreceivemb = $mreceive.sum / (1024 * 1024)
    $vreceive = "{0:N2}" -f $mreceivemb + " MB"
    $bigreceive = $mreceive.maximum / (1024 * 1024)
    $avreceive = $mreceive.average / 1024

    $bigreceivemb = "{0:N2}" -f $bigreceive + " MB"
    $avreceivekb = "{0:N2}" -f $avreceive + " KB"

    #$senders = $send | Group-Object Sender | Sort-Object Count -Descending
    #$topsender = $senders[0].Name
    #$topsender += $senders[0].Count

    #$receivers = $receive | Group-Object Recipients | Sort-Object Count -Descending
    #$topreceiver = $receivers[0]
    #$topreceiver

    $computer = gc env:computername
    $obj = new-object psObject

    $obj |Add-Member -MemberType noteproperty -Name "Generated on server:" -Value $Computer
    $obj |Add-Member -MemberType noteproperty -Name "Date :" -Value $Datum
    $obj |Add-Member -MemberType noteproperty -Name "Sent mails :" -Value $msend.Count
    $obj |Add-Member -MemberType noteproperty -Name "Size of sent mails:" -Value $vsend
    $obj |Add-Member -MemberType noteproperty -Name "Size of biggest mail out:" -value $bigsendmb
    $obj |Add-Member -MemberType noteproperty -Name "Average size out :" -value $avsendkb
    $obj |Add-Member -MemberType noteproperty -Name "Quantity incoming mails :" -Value $mreceive.Count
    $obj |Add-Member -MemberType noteproperty -Name "Size of received mails :" -Value $vreceive
    $obj |Add-Member -MemberType noteproperty -Name "Size of biggest mail in :" -value $bigreceivemb
    $obj |Add-Member -MemberType noteproperty -Name "Average size in :" -value $avreceivekb
    $obj |Add-Member -MemberType noteproperty -Name "Overall quantity :" -Value $anzahl
    $obj |Add-Member -MemberType noteproperty -Name "Overall size :" -Value $volumen

    $out = $Datum + ";" + $msend.count + ";" + $vsend + ";" + $mreceive.count + ";" + $vreceive + ";" + $anzahl + ";" + $volumen
    $out | out-file c:\daily.csv -append -encoding default

    function sendmail($body)
    {
    $SmtpClient = new-object system.net.mail.smtpClient
    $MailMessage = New-Object system.net.mail.mailmessage
    $SmtpClient.Host = "smtp-relay.example.com"
    $mailmessage.from = "WA1ZMZMB02@example.com"
    $mailmessage.To.add("robkessler@example.com")
    # $mailmessage.CC.add("CC_RECIPIENT@YOURexample.com")
    $mailmessage.Subject = “Exchange daily message Report $Datum”
    $MailMessage.IsBodyHtml = $false
    $mailmessage.Body = $body

    $smtpclient.Send($mailmessage)
    }

    $obj = $obj -replace("@{","")
    $obj = $obj -replace("=",":`t")
    $obj = $obj -replace("; ","`n")
    $obj = $obj -replace("}","`n")

    sendmail $obj
