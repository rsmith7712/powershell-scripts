# LEGAL
<# LICENSE
    MIT License, Copyright 2017 Richard Smith

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
    Revoke_CRM_License.ps1

.DESCRIPTION
    		Revokes CRM licenses from all outreach accounts.

.FUNCTIONALITY
    		Revokes CRM licenses from all outreach accounts.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = Get-Date -Format "HHmmss"
$Script:Logfile = "C:\temp\Remove_CRM_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "Username, License"
function Append-Log($message)
{
	Add-Content $Script:LogFile "$message"
}
# ----------------------------------------------------------------------------------------------

Connect-MsolService

#get a list of outreach accounts

$users = (Get-ADUser -SearchBase "OU=StoreOutreach,OU=Service Accounts,OU=Domain Services,DC=domain,DC=com" -Filter *).userprincipalname
#$users = Get-Content C:\temp\Outreach.txt

#$outreaches = @()

foreach($user in $users)
{
    $licensecheck = (Get-MsolUser -UserPrincipalName $user).licenses.accountskuid

    if($licensecheck -eq "domain:CRMSTANDARD")
    {
        #$outreaches += $user
        Set-MsolUserLicense -UserPrincipalName $user -RemoveLicenses domain:CRMSTANDARD
        #Get-MsolUser -UserPrincipalName $user
        if($? -eq $False)
        {
            Append-Log "$user, Failed"
        }
        Else
        {
            Append-Log "$user, License Revoked"
        }
        
    }
    else
    {
        Append-Log "$user, Not Exist"
    }
}

#$outreaches.Count
