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
    Apply_CRM_License.ps1

.DESCRIPTION
    		Applies CRM licenses to all US store accounts.

.FUNCTIONALITY
    		Applies CRM licenses to all US store accounts.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = Get-Date -Format "HHmmss"
$Script:Logfile = "C:\temp\Apply_CRM_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "Username, License"
function Append-Log($message)
{
	Add-Content $Script:LogFile "$message"
}
# ----------------------------------------------------------------------------------------------

#$userpull = (Get-ADUser -SearchBase "ou=store users,ou=store accounts,dc=domain,dc=com" -filter *).userprincipalname
$userpull = Get-Content C:\temp\US_Stores.txt

$stores = @("1","5","8")

Connect-MsolService

#$USstores = @()

foreach($user in $userpull)
{
    $checkuser = $user.substring(0,7)
    $check = (Get-ADUser $checkuser).name

    if($check -like "*lab*")
    {
        Append-Log "$user, Lab Account"
    }
    else
    {
        if($stores -contains $user.substring(0,1))
        {
            #Set-MsolUserLicense -UserPrincipalName $user -PreferredDataLocation US
            Set-MsolUserLicense -UserPrincipalName $user -AddLicenses domain:CRMSTANDARD
            #Get-MsolUser -UserPrincipalName $user
            #$USstores += $user
            if($? -eq $False)
            {
                Append-Log "$user, Failed"
            }
            Else
            {
                Append-Log "$user, License Applied"
            }
        }
        else
        {
            append-log "$user, License Not Applied"
        }
    }
}

#$USstores.count