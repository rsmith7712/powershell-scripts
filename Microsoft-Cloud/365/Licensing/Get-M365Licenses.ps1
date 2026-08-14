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
    Get-M365Licenses.ps1

.DESCRIPTION
    Reports the disabled license service options for Microsoft 365 users (by UPN) via MSOnline.

.FUNCTIONALITY
    Reports Microsoft 365 disabled license options.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#
[cmdletbinding()]
param
(
    [switch]$Single
)
#>
Function Get-DisabledLicenseOptions($upn)
{
    (Get-MsolUser -UserPrincipalName $upn).Licenses | ForEach {
    $License = $_
        $DisabledOptions = @()
        $License.ServiceStatus | ForEach-Object{
            $pStatus = 
            If ($pStatus -eq "Disabled") #-or  $_.ServicePlan.ServiceName -like "*YAMMER*")
            {
                $DisabledOptions += "$($_.ServicePlan.ServiceName)"
            } 
        }
        $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $License.AccountSkuId -DisabledPlans $DisabledOptions
        Set-MsolUserLicense -UserPrincipalName $upn -LicenseOptions $LicenseOptions
        $aSkuId = $License.AccountSkuId
        $DisabledOptions | ForEach-Object {
            $dObject = $_
            Write-Host "$upn : $aSkuId - $dObject" -ForegroundColor Green
            #"$upn,$aSkuId,$dObject" | Out-File $outfile ascii -Append
        }
    }
}#=========================================[End Function]==========================================
$usr = $env:USERNAME + "@" + $env:USERDNSDOMAIN
$creds = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist $usr
Install-Module MSOnline
Import-Module MSOnline
Connect-MsolService -Credential $creds

Clear-Host

Connect-MsolService

    $single = Read-Host "Do you want to run this against a (s)ingle user, a (l)ist or (a)ll users?"
    switch ($Single)
    {
    "s"
        {
            $upn = Read-Host "Enter the user's UPN ['user@example.com' format]"
            Get-DisabledLicenseOptions -upn $upn
            Start-Sleep -Seconds 5
            Break
        }
     "l"
        {
            $userNames = Get-Content "\\SERVER\SHARE\...\users.txt"
            $userNames | 
            ForEach-Object{
            $upn = (Get-ADUser -filter "Name -like '$($_)'").UserPrincipalName
            Get-DisabledLicenseOptions -upn $upn
            }
        }
     "a"
        {
            "Upn,AccountSkuId,DisabledLicenseOption" | Out-File $outfile ascii -Append
            Get-MsolUser -all | Where-Object {($_.licenses).accountskuid -match "ENTERPRISEPACK"} | ForEach {
            $upn = $_.UserPrincipalName
            Get-DisabledLicenseOptions -upn $upn
        }
    }
}
#Invoke-Item $outfile