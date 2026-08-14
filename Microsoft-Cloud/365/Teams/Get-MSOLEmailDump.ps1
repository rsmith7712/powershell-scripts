# LEGAL
<# LICENSE
    MIT License, Copyright 2019 Richard Smith

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
    Get-MSOLEmailDump.ps1

.SYNOPSIS
 Get-MSOLEmailAddressDump.ps1
 
.DESCRIPTION
 Get-MSOLEmailAddressDump.ps1

.EXAMPLE
  
.NOTES
  Version:        1.0
  Author:         user10
  Creation Date:  01/22/2019
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0 (01/22/2019)
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Get-MSOLEmailAddressDump.ps1

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Initializations
#################################
$Script:ProductName = "Export_MSOLEmailList" #Fill this in. Do not put the "TEAM_" prefix
$ErrorActionPreference = "SilentlyContinue" #Maybe change to "SilentlyContinue" for Production.

# Functions
#################################
Function Log_ToSplunk
{
    Param(
        [parameter(Mandatory=$true,
        Position=0)]
        [String]
        $Message,
    
        [parameter(Mandatory=$false,
        Position=1)]
        [String]
        $Type = "Log",

        [parameter(Mandatory=$false,
        Position=2)]
        [String]
        $Status = "Informational",
    
        [parameter(Mandatory=$false,
        Position=3)]
        [int]
        $ID = $Null
    )
    
    $product = "team_" + $Script:ProductName
    $uri = "https://hecext.example.com:18443/services/collector/event"
    $header = @{}
    $header.add('Content-Type', 'application/json')
    $header.add('Authorization', 'Splunk Application-Key-Here')
    $body = @{
        sourcetype = 'domain:ps:log'
        host = $env:COMPUTERNAME
        event = @{
            message = $Message
            user = $env:USERNAME
            product = $Product
            type = $Type
            status = $Status
            id = $ID
        }
    }
    $body = $body | ConvertTo-Json
    Invoke-WebRequest -Uri $uri -Method Post -Headers $header -Body $body | Out-Null
}
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Function Send-Email($attachment)
{
    $smtp = "smtpi.example.com"
    $to = "user30@example.com", "shines@example.com", "user31@example.com", "user33@example.com"
    $from = "Domain Automation <donotreply@example.com>"
    $subject = "Domain Monthly Email Address Export"
    $body = "The attachment in this email contains a list of updated user email addresses exported from the Domain O365 online environment.</br></br><A HREF='mailto:a-team@example.com'>Domain Automation Team</A>"
    Try
    {                                    
        Send-MailMessage -SmtpServer $smtp -To $to -From $from -Subject $subject -Body $body -BodyAsHtml -attachments $attachment        

        $output = "SUCCESS: Domain MSOL email address list export ($($attachment)) successfully emailed to $($to)"
        Log_ToSplunk -Message $output -Status "Success"
        Write-Host $output -ForegroundColor Cyan
    }
        Catch
        {
            $output = "ERROR: Exception Message - $($_.Exception.Message). Exiting script"
            Log_ToSplunk -Message $output -Status "Fail"
            Write-Host $output -ForegroundColor Yellow
            Start-Sleep -Seconds 05
            Exit 1
        }
}
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function Get-Credentials
{
    $username = "svc_UsrMgmt@example.com"
    $password = ConvertTo-SecureString -AsPlainText -Force -String "<password>"
    $script:cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $username,$password
}
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function Get-EmailAddresses($csv)
{
    Get-Credentials
    Try
    {
        Connect-MsolService -Credential $script:cred

        $output = "SUCCESS: Connection to MSOL service successful."
        Log_ToSplunk -Message $output -Status "Success"
        Write-Host $output -ForegroundColor Cyan
    }
        Catch
        {
            $output = "ERROR: Get-EmailAddresses function failed. Connection to O365 service failed. Exception Message - $($_.Exception.Message). Exiting script"
            Log_ToSplunk -Message $output -Status "Fail"
            Write-Host $output -ForegroundColor Yellow
            Start-Sleep -Seconds 05
            Exit 1
        }
    Try
    {
        Get-MsolUser -All | where {$_.isLicensed -eq $true} | 
        Select LastName, FirstName, @{Name="PrimaryEmailAddress";Expression={($_.ProxyAddresses | ?{$_ -cmatch '^SMTP\:.*'}).split(":")[1]}} |
        Export-Csv -Path $csv -NoTypeInformation

        $output = "SUCCESS: Domain MSOL email address list successfully exported to $($csv)"
        Log_ToSplunk -Message $output -Status "Success"
        Write-Host $output -ForegroundColor Cyan
    }
        Catch
        {
            $output = "ERROR: Get-EmailAddresses function failed. Exception Message - $($_.Exception.Message). Exiting script"
            Log_ToSplunk -Message $output -Status "Fail"
            Write-Host $output -ForegroundColor Yellow
            Start-Sleep -Seconds 05
            Exit 1
        }
}
# Script Starts
#################################
Log_ToSplunk -Message "Script Starting. https://domain.sharepoint.com/sites/TheA-Team/Lists/Automation%20Inventory/AllItems.aspx" -Type "Begin" -Status "Informational"

$export = "C:\temp\MSOL_EmailAddress_Export.csv"
Get-EmailAddresses -csv $export
Send-Email -attachment $export

        # Script Ends
#################################
Log_ToSplunk -Message "Script Ending. https://domain.sharepoint.com/sites/TheA-Team/Lists/Automation%20Inventory/AllItems.aspx" -Type "End" -Status "Informational"