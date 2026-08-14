<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 9/19/2017
    Organization: Domain, Inc.
    Filename: Send-MailAlert.ps1
    =========================================================
    .DESCRIPTION
        [ENTER A BRIEF DESCRIPTION OF SCRIPT AND ITS PURPOSE]

    .VERSION INFO
        [ENTER ANY CHANGES MADE HERE]
#>

# ----------------------------------------------------------------------------------------------
# Functions

function Send_Email($Store) {
    $smtp = "smtpi.example.com"
    $to = "pctechnicians@example.com"
    #$cc = 
    $bcc = "servicedesk@example.com"
    $from = "SQL Service Alerts <sqlservicealerts@example.com>"
    $subject = "SQL Express Service on $store is Not Running"
    $body = "Please transfer ticket to desktop support for remediation."  
    send-MailMessage -SmtpServer $smtp -To $to -Bcc $bcc -From $from -Subject $subject -Body $body -BodyAsHtml
}

# ----------------------------------------------------------------------------------------------
# Variables

$store = $env:COMPUTERNAME

# ----------------------------------------------------------------------------------------------
# Script

Send_Email $store