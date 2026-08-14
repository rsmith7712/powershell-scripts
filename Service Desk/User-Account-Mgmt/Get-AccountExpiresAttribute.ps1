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
    Get-AccountExpiresAttribute.ps1

.SYNOPSIS
 Get-ContractorAccountStatus.ps1

.DESCRIPTION
 Pulls the accountExpires attribute from AD for Domain contractor accounts to determine
 which accounts have been set to expire, which accounts are active, and which have already expired. The output
 is emailed to a recipient if requested.  This script is designed to be executed on a periodic 
 basis by a scheduled task.
    
.EXAMPLE
 Get-ContractorStatus.ps1  

.NOTES
  Version:        1.1
  Author:         user10
  Creation Date:  8/20/2019
  Purpose/Change: Initial Script Development

.HISTORY

.FUNCTIONALITY
    Pulls the accountExpires attribute from AD for Domain contractor accounts to determine
     which accounts have been set to expire, which accounts are active, and which have already expired. The output
     is emailed to a recipient if requested.  This script is designed to be executed on a periodic
     basis by a scheduled task.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Initializations
#################################

$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$Script:ProductName = "Get-ContractorAccountStatus"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName).txt"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
if(Test-Path $Script:Logfile){rm $Script:Logfile}
$ErrorActionPreference = "SilentlyContinue"

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
}#---------[END Function]---------
Function Append-Log($message)
{   
    $thetime = Get-Date -Format g
    "$thetime`: $message" | Out-File $Script:Logfile -Append
}#---------[END Function]---------
Function Return-Output($message,$color="white")
{
    $ErrorActionPreference = "SilentlyContinue"
    $thetime = Get-Date -Format g
    Write-Host "$thetime`: $message" -ForegroundColor $color
}#---------[END Function]---------
Function Get-ContractorAccountStatus ($outfile)
{
    $useraccounts = get-aduser -filter * -SearchBase "OU=External Accounts,OU=Domain Services,DC=DOMAIN,DC=com" -Properties AccountExpires
    $results = ForEach($useraccount in $useraccounts){
    $expires = $useraccount.AccountExpires
    $username = $useraccount.Name
    $useraccount = $useraccount.SamAccountName
        if(!(($expires -eq 9223372036854775807) -or ($expires -eq 0)))
        {
            $expiresdate = [DateTime]::FromFileTimeutc($expires)
            if ($expiresdate -lt (get-date))
            {
                $expiresstatus = "Expired"
            }
                else
                {
                        $expiresstatus = "Active"
                }
        }
            else
            {
                $expiresstatus = "Never Expires"
                $expiresdate = "Not Set"    
            }
            [PSCustomObject]@{
                UserName = $username
                UserAccount = $useraccount
                ExpiredStatus = $expiresstatus
                ExpiresDate = $expiresdate
            }
    }
    $results | Export-Csv -Path $outfile -NoTypeInformation
}#--------------[END Function]--------------
Function Send-EmailStatus ($outfile)
{
    Try 
    {
        $mailbody = Import-Csv -Path $outfile | Format-List  | Out-String
        $mailbody
        $smtp = "smtpi.example.com"
        $to = "a-team@example.com","PCTechnicians@example.com"
        $from = "Domain Automation <donotreply@example.com>"
        $subject = "Domain Contractor Account Expiration Status Report"               
        Send-MailMessage -SmtpServer $smtp -To $to -From $from -Subject $subject -Body $mailbody -Attachments $outfile
        $output = "SUCCESS: Scheduled email to $($to) subject = $subject via smtp server: $($smtp) sent successfully."
        Log_ToSplunk -Message $output -Status "SUCCESS"
    }
        Catch
        {
            $output = "FAILURE: Scheduled email to $($to) subject = $subject via smtp server: $($smtp) did not send successfully."
            Log_ToSplunk -Message $output -Status "Fail"
        }

}#--------------[END Function]--------------

######### Script Starts #########
$output = "$($Script:ProductName).ps1 script starting."
Log_ToSplunk -Message $output -Type "Begin" -Status "Informational"
Clear-Host

$outfile = "$script:script_dir\ContractorAccountStatus.csv"
Get-ContractorAccountStatus -outfile $outfile
Send-EmailStatus -outfile $outfile

$output = "$($Script:ProductName).ps1 script starting."
Log_ToSplunk -Message $output -Type "End" -Status "Informational"
Exit
########## Script Ends ##########