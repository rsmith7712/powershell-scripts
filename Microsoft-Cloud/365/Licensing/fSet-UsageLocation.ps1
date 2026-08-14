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
    fSet-UsageLocation.ps1

.DESCRIPTION
    Connects to Microsoft Teams/365 with a service account to set user usage-location values.

.FUNCTIONALITY
    Sets Microsoft 365 user usage location.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>


#########################################[Script Starts]###########################################

Clear-Host
Import-Module MicrosoftTeams
$tpw = ConvertTo-SecureString -String '<password>' -AsPlainText -Force
$tUsr = 'svc_TeamsAutomation@example.com'
Try
{
    $script:creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $tUsr, $tPw
}
    Catch
    {
        Write-Host "$($_.Exception.Message)" -fc "Cyan"
    }
Try
{
    $teamsSession = New-CsOnlineSession -Credential $script:creds
    Import-PSSession $teamsSession -AllowClobber
}
    Catch
    {
        Write-Host "$($_.Exception.Message)" -fc "Cyan"
    }
Get-PSSession | Enter-PSSession
$upns = "user2@example.com"#,"hoh@example.com","admin2@example.com"
foreach($upn in $upns){
        Get-MsolUser -All | where{$_.UsageLocation -ne "US"} | foreach{set-msoluser -UserPrincipalName $_.UserPrincipalName -UsageLocation "US"}
    }
# ------------------------------------------------------------------
        # Remove MS Teams dial-out policy
        #Grant-CsDialoutPolicy -identity $($_) -PolicyName $Null
Exit-PSSession
Get-PSSession | Remove-PSSession
#########################################[Script Ends]#############################################