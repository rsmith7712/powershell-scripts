<#
.NOTES
Filename:   SMTP-Validation-Send-TestEmal.ps1
Author:     Surender Kumar
Editor:     Richard Smith
URL:        https://www.techtutsonline.com/send-test-email-using-smtp-relay-in-powershell/

.DESCRIPTION
    Send Test Email using SMTP relay in PowerShell

.EXAMPLE
    Send-TestEmail -SMTPServer 'smtp.sendgrid.net' -Username 'YourName' -FromEmail 'noreply@example.com' -ToEmail 'user@company.com' -Port 587

#>
function Send-TestEmail{
    [cmdletbinding()]
    Param (
    [Parameter(Mandatory=$true)]
        [String]$SMTPServer,
    [Parameter(Mandatory=$true)]
        [String]$Username,
    [Parameter(Mandatory=$true)]
        [String]$FromEmail,
    [Parameter(Mandatory=$true)]
        [String]$ToEmail,
    [Parameter(Mandatory=$true)]
        [int32]$Port
   )
   Process{
        $SecurePassword = Read-Host "Please type the password for $Username" -AsSecureString
        $Credentials = New-Object System.Management.Automation.PsCredential($Username, $SecurePassword)
        $Subject = "SMTP Server Test"
        $Body = "Hello, <br><br> This email message was sent to check the SMTP functionality. Please ignore this message.<br><br> Thank you!"

        Try {
                Send-MailMessage -From $FromEmail -To $ToEmail -Subject $Subject -Body $Body `
                -Priority High -SmtpServer $SMTPServer -Credential $Credentials -UseSsl -Port $Port `
                -BodyAsHtml -ErrorAction Stop `
                Write-Host "The test email was successfully sent. Please check the inbox of $ToEmail." `
                -ForegroundColor Green
            }
            Catch
                {
                    Write-Host "Failed to send the email. Please make sure that the information entered is correct." -ForegroundColor Red
                }
            }
        }
        Send-TestEmail -SMTPServer 'smtp-relay.example.com' -Username 'richard' -FromEmail 'noreply@example.com' -ToEmail 'user@company.com' #-Port 587
