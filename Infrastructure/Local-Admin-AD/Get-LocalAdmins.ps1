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
    Get-LocalAdmins.ps1

.DESCRIPTION
    Reports whether a specified member belongs to the local Administrators group on a computer (via WMI).

.FUNCTIONALITY
    Checks local Administrators group membership.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

function get-localadmin
{  
    param ($computer,$member)
    Try
    {
        $admins = Gwmi win32_groupuser –computer $computer -ErrorAction Stop
        $admins = $admins |? {$_.groupcomponent –like '*"Administrators"'}  
  
        $admins | foreach {  
            $_.partcomponent –match “.+Domain\=(.+)\,Name\=(.+)$” > $nul  
            $m = $matches[1].trim('"') + “\” + $matches[2].trim('"')|findstr /I "$member"
            If ($m -eq $member)
            {
                $output = "SUCCESS: $($m) is a local Administrator on $computer."
            }
        }
    }
        Catch
        {
            $output = "ERROR: Unable to return local administrators on $computer. Exception Message: $_.Exception.Message."
        }
    return $output
}
Write-Output "Checking local administrator membership on affected computers."
$computers = "site","site","site"
    $computers|foreach{
    $adminmember = "DOMAIN\orgadmins"
    $computer  = $_
    $admintest = get-localadmin -computer $computer -member $adminmember
    if ($admintest -ne $null)
    {
        Write-Output $admintest
    }
        else
        {
           Write-Output "ERROR: $adminmember not a local administrator on $computer."
        }
}