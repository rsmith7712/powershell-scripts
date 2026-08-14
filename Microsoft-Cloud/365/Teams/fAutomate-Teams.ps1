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
    fAutomate-Teams.ps1

.DESCRIPTION
    Connects to Microsoft Teams using a stored service-account credential as the entry point for Teams automation.

.FUNCTIONALITY
    Authenticates a Microsoft Teams automation session.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Clear-Host
Get-PSSession | Remove-PSSession
Import-Module MicrosoftTeams
$tpw = ConvertTo-SecureString -String '<password>' -AsPlainText -Force
$tUsr = 'svc_TeamsAutomation@example.com'
Try
{
    $script:creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $tUsr, $tPw
}
    Catch
    {
        Write-Host "$($_.Exception.Message)" -ForegroundColor Cyan
    }
#Connect-MicrosoftTeams -Credential $script:creds
Try
{
    $teamsSession = New-CsOnlineSession -Credential $script:creds
    Import-PSSession $teamsSession -AllowClobber
}
    Catch
    {
        Write-Host "$($_.Exception.Message)" -ForegroundColor Cyan
    }
Get-PSSession | Enter-PSSession
#################[Script Starts]#################
$upns = "user2@example.com","hoh@example.com","admin2@example.com"
foreach($upn in $upns){
    <#
        # Get User properties
        Get-CsOnlineUser -identity $upn
        # Remove policy
        Grant-CsDialoutPolicy -identity $upn -PolicyName $Null
    #>
        # Assign Dial-Out policy
        Grant-CsDialoutPolicy -identity $upn -PolicyName "DialoutCPCandPSTNInternational"
    }
###################[Script Ends]#################
#Disconnect-MicrosoftTeams
Get-PSSession | Remove-PSSession