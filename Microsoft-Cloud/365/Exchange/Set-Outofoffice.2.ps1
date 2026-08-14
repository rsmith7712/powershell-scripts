<#
    .INFORMATION
    =========================================================
    Created By: William Caress
    Created On: 08/19/2017
    Organization: Domain, Inc.
    Filename: Set-Outofoffice.ps1
    =========================================================
    .DESCRIPTION
        Sets and out of office message for specified user.

    .VERSION INFO
        v1 - Initial Build
#>

# ----------------------------------------------------------------------------------------------
# Variables

$user = Read-Host "Enter User Name"
$sdate = Read-Host "Start Date - Example: "7/10/2015 08:00:00" | Please leave blank if not needed "
$edate = Read-Host "End Date - Example: "7/10/2015 08:00:00" | Please leave blank if not needed "
$msg = "Thank you for your request for sponsorship.

Please note the following information and requests.

Along with your sponsorship details, we would like to see the following:
What is the event and when will it be held?
Where will the financial contribution be applied?
How will this event impact Domain?
Download the form here

Due Dates:
All sponsorship requests for Q1/Q2 need to be received by October 2nd
All Sponsorship requests for Q3/Q4 need to be received by July 2nd

Thank you,
You’re Sponsorship Committee

** Please note that responses will be sent on a quarterly basis **

Thank you!

"

# ----------------------------------------------------------------------------------------------
# Script


Write-Host 'Connecting to Office 365 PowerShell' -ForegroundColor Yellow
$O365Cred = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $O365cred -Authentication Basic -AllowRedirection
if($? -eq $true)
{
    Write-Host 'Connection to Office 365 Successful' -ForegroundColor Yellow
}
else 
{
    Write-Host 'Connection to Office 365 Failed. Please try again.' -ForegroundColor Red
    exit
}

Write-Host 'Importing Office 365 PSSession' -ForegroundColor Yellow
Import-PSSession $Session -DisableNameChecking -AllowClobber |Out-Null
if($? -eq $true)
{
    Write-Host 'PSSession Importing has been Completed' -ForegroundColor Yellow
}
else 
{
    Write-Host 'PSSession could not be imported.  Please Try Again.'
    exit
}

if(($sdate -and $edate) -eq $true)
{
    Set-MailboxAutoReplyConfiguration -Identity $user -AutoReplyState Enabled -InternalMessage $msg -ExternalMessage $msg -starttime $sdate -endtime $edate
    if($? -eq $true)
    {
        Write-Host 'Auto-Reply Message set succesfully.'
    }
    else 
    {
        Write-Host 'Auto-Reply Message was not set.  Please try again.'
        exit
    }
}
else 
{
    Set-MailboxAutoReplyConfiguration -Identity $user -AutoReplyState Enabled -InternalMessage $msg -ExternalMessage $msg
    if($? -eq $true)
    {
        Write-Host 'Auto-Reply Message set succesfully.'
    }
    else 
    {
        Write-Host 'Auto-Reply Message was not set.  Please try again.'
        exit
    }
}