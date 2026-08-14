# LEGAL
<# LICENSE
    MIT License, Copyright 2021 Richard Smith

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
    Get-StoreIPs_dev.ps1

.DESCRIPTION
    Determines a store's region (US, Canada or Australia) from its UFO_NUMBER as part of resolving store IPs (dev).

.FUNCTIONALITY
    Resolves a store's region from its number.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Function Get-RegionCode
{
    Param(
    [parameter(Mandatory=$true,Position=0)]
    [string]$UFO_NUMBER
    )
    $global:regioncode = $strnmbr.Substring(0,1)
    If ($regioncode -eq 1){$region = "US"}
    If ($regioncode -eq 2){$region = "Canada"}
    If ($regioncode -eq 3){$region = "Australia"}
    Write-Host "Region value set to $region" -ForegroundColor Yellow
}#------------[END Get-RegionCode]------------
Function Get-StoreIPs{
    Param(
    [parameter(Mandatory=$true,Position=0)]
    [string]$UFO_NUMBER
    )
    # Sets 2nd & 3rd IP address octets based on store #
    $oct2a = $UFO_NUMBER.Substring(0,1)
    $oct2b = $UFO_NUMBER.Substring(1,1)
    $oct3a = $UFO_NUMBER.Substring(2,1)
    $oct3b = $UFO_NUMBER.Substring(3,1)
    if($oct2a -gt 0){$oct2 = ("$oct2a" + "$oct2b")} else { $oct2 = "$oct2b"}
    if($oct3a -gt 0){$oct3 = ("$oct3a" + "$oct3b")} else { $oct3 = "$oct3b"}
    # Generate store network device IP addresses
    $global:FWip = "10."+"$oct2."+"$oct3."+"225"
    $global:MSWip = "10."+"$oct2."+"$oct3."+"226"
    $global:RSWip = "10."+"$oct2."+"$oct3."+"227"
    $a = (1..9)
    $a | ForEach-Object {
        $apname = "AP" + $_
        $apip = "AP" + $_ + "ip"
        $ipvalue = "10."+"$oct2."+"$oct3."+"23" + $_
        $namevalue = $UFO_NUMBER +  "-AP" + $_
        New-Variable $apip $ipvalue -Scope "Global" -Force
        New-Variable $apname $namevalue -Scope "Global" -Force
        }
    "Firewall: $FWip"
    "Manager Switch: $MSWip"
    "Register Switch: $RSWip"
    "Access Point IP range ($ap1`:$ap9): $ap1ip - $ap9ip"
}#------------[END Get-StoreIPs]------------

$strnmbr = Read-Host -Prompt "Enter UFO_NUMBER"
Get-RegionCode -UFO_NUMBER $strnmbr
Get-StoreIPs -UFO_NUMBER $strnmbr