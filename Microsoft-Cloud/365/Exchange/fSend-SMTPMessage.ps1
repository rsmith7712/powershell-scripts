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
    fSend-SMTPMessage.ps1

.DESCRIPTION
    Sends status email through an authenticated SMTP relay, wrapped in a logging framework (log file, run id, append-log helper).

.FUNCTIONALITY
    Sends automated status emails over SMTP with logging.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$script:ScriptName = "Send-SMTPMessage.ps1"
[string]$script:datestamp = (Get-Date).ToString("yyyyMMdd")
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$script:uid =([string](Get-Date -UFormat "%y%m%d") + ".ATM." + [string](Get-Random -Minimum 1000000000 -Maximum 9999999999))
$Script:ProductName = "Send-SMTPMessage"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName).log"
$Script:FixMe = "$script:script_dir\logs\$($Script:ProductName)_FixMe.log"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
if(Test-Path $Script:Logfile){Remove-Item $Script:Logfile}
$ErrorActionPreference = "SilentlyContinue"

Function Append-Log
{
    param
    (
        [parameter(Mandatory=$true,Position=0)][string]$message,
        [parameter(Mandatory=$false,Position=1)][string]$color = "White"
    )
    $ErrorActionPreference = "SilentlyContinue"
    $thetime = Get-Date -Format g
    Write-Host "$thetime`: $message" -ForegroundColor $color
    "$thetime`: $message" | Out-File $script:logfile -Append
}#=======================================[ End Function ]==========================================
Function Send-EmailStatus ($subject,$message,$attachment)
{
    $username = "svc_UsrMgmt@example.com"
    $password = ConvertTo-SecureString -AsPlainText -Force -String "<password>"
    $script:cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $username ,$password
    Try 
    {
        $smtp = "smtpi.example.com"
        $to = "a-team@example.com"
        $from = "Domain Automation <donotreply@example.com>"
        $signature = "</br></br><A HREF='mailto:a-team@example.com'>Domain Automation Team</A>"
        $body = "$signature`n$message"
        Send-MailMessage -SmtpServer $smtp -To $to -From $from -Subject $subject -Body $body -BodyAsHtml -attachments $attachment -Credential $script:cred
        Append-Log -message "SUCCESS: Scheduled email to $($to) subject = $subject via smtp server: $($smtp) sent successfully."
    }
        Catch
        {
            Append-Log -message "FAILURE: Scheduled email to $($to) subject = $subject via smtp server: $($smtp) did not send successfully."
        }
}#=========================================[End Function]==========================================
Append-Log -message "Sent from $($env:COMPUTERNAME)."
$message = "This is a test email."
$subject = "Domain SMTP Test Message"
Send-EmailStatus -message $message -subject $subject -attachment $Script:Logfile