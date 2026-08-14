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
    Get-Outreach.ps1

.DESCRIPTION
    Compares store user accounts (with email) against the Store Outreach service accounts to reconcile outreach coverage.

.FUNCTIONALITY
    Reconciles store accounts against outreach accounts.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>


$Stores = Get-ADuser -Filter * -SearchBase "OU=Store Users,OU=Store Accounts,DC=DOMAIN,DC=COM" -Properties EmailAddress

$OutReach = Get-ADuser -Filter * -SearchBase "OU=StoreOutreach,OU=Service Accounts,OU=Domain Services,DC=DOMAIN,DC=COM"

$OutPut1 = @{}
$OutPut2 = @{}

ForEach($Store in $Stores)
{
    $Found = $Null
    If($Store.GivenName.length -ne 4)
    {
        Continue
    }
    else
    {
        ForEach($Acct in $Outreach)
        {
            If($Store.Surname -eq $Acct.GivenName)
            {
                $OutPut1.Add($Store.GivenName, $Acct.samaccountname)
                $Found = $True
                Continue
            }

        }
    }
    If($Found -ne $True)
    {
        $OutPut1.Add($Store.GivenName,"No Match Found")
    }
}

ForEach($Acct in $Outreach)
{
    $Found = $Null
    ForEach($Store in $Stores)
    {
        If($Store.GivenName.length -ne 4)
        {
            Continue
        }
        ElseIf($Acct.GivenName -eq $Store.Surname)
        {
            $OutPut2.Add($Acct.samaccountname, $Store.EmailAddress)
            $Found = $True
            Continue
        }
    }
    If($Found -ne $True)
    {
        $OutPut2.Add($Acct.samaccountname,"No Match Found")
    }
}

$OutPut1.GetEnumerator() | Export-CSV C:\Software\StoreCheck.csv -NoTypeInformation
$OutPut2.GetEnumerator() | Export-CSV C:\Software\OutreachCheck.csv -NoTypeInformation