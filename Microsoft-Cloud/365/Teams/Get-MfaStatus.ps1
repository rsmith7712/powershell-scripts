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
    Get-MfaStatus.ps1

.DESCRIPTION
    Connects with a Microsoft Teams/365 service account and reports the multi-factor authentication status of users.

.FUNCTIONALITY
    Reports Microsoft 365 user MFA status.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>


$tpw = ConvertTo-SecureString -String '<password>' -AsPlainText -Force
$tUsr = 'svc_TeamsAutomation@example.com'
$ErrorActionPreference = "Stop"
Try
{
    $script:creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $tUsr, $tPw
}
    Catch
    {
        Append-Log -message "$($_.Exception.Message)" -color "Magenta"
    }
Connect-MsolService -Credential $script:creds
$Result=@() 
$users = Get-MsolUser -All
$users | ForEach-Object {
$user = $_
$mfaStatus = $_.StrongAuthenticationRequirements.State 
$methodTypes = $_.StrongAuthenticationMethods 
 
if ($mfaStatus -ne $null -or $methodTypes -ne $null)
{
if($mfaStatus -eq $null)
{ 
$mfaStatus='Enabled (Conditional Access)'
}
$authMethods = $methodTypes.MethodType
$defaultAuthMethod = ($methodTypes | Where{$_.IsDefault -eq "True"}).MethodType 
$verifyEmail = $user.StrongAuthenticationUserDetails.Email 
$phoneNumber = $user.StrongAuthenticationUserDetails.PhoneNumber
$alternativePhoneNumber = $user.StrongAuthenticationUserDetails.AlternativePhoneNumber
}
Else
{
$mfaStatus = "Disabled"
$defaultAuthMethod = $null
$verifyEmail = $null
$phoneNumber = $null
$alternativePhoneNumber = $null
}
    
    $Result += New-Object PSObject -property @{ 
        UserName = $user.DisplayName
        UserPrincipalName = $user.UserPrincipalName
        MFAStatus = $mfaStatus
        AuthenticationMethods = $authMethods
        DefaultAuthMethod = $defaultAuthMethod
        MFAEmail = $verifyEmail
        PhoneNumber = $phoneNumber
        AlternativePhoneNumber = $alternativePhoneNumber
    }
}

$Result
$Result | Select-Object UserName,UserPrincipalName,MFAStatus,MFAEmail,PhoneNumber,AlternativePhoneNumber | 
Export-csv "\\SERVER\SHARE\...\mfa_status20210316.csv" -NoTypeInformation
